//
//  SlotDrag.swift
//  Topster
//

import SwiftUI
import UIKit

/// The grid's coordinate space. Slot frames, the finger and the floating cover
/// are all measured in it, so a cover can travel between rows that each scroll
/// on their own.
enum GridSpace {
    static let name = "grid"
}

/// Every slot's frame in `GridSpace`, reported by `GridSlotCell`.
struct SlotFramesKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// True while a cover is held, reported up to FortyGridView so the page's
/// vertical scroll holds still under a drag.
struct SlotHeldKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// What one slot draws differently while a cover is held or in flight. One per
/// slot, so a change to one slot redraws that cell and no other.
@Observable
final class SlotState {
    /// This slot's cover is being held: draw it dimmed.
    var isSource = false
    /// The finger is over this slot: draw it at the press scale.
    var isTarget = false
    /// Set while covers are in flight to or from this slot: what it held
    /// before the drop, drawn instead of the grid's contents. An album is
    /// drawn as a ghost at `dimOpacity`, the way a held cover leaves its slot;
    /// `.some(nil)` is the empty square it was.
    var override: Album?? = nil
    /// After a move, the origin's ghost fades out over the grey square it
    /// leaves, instead of snapping to empty.
    var isClearing = false
    /// The empty square's plus, held back for a beat so it fades in after a
    /// move rather than popping.
    var isPlusHidden = false
}

/// Hold-and-drag state for the grid. GridContent owns one and hands it to every
/// `GridSlotCell` through the environment.
///
/// Covers in motion are drawn above all the rows by `FloatingCover`. Inside a
/// row they would be clipped by that row's scroll view the moment they left
/// it. Cells report their frames in `GridSpace`, and the finger is hit-tested
/// against those frames.
///
/// A drop writes the grid at once, so persistence and analytics never wait on
/// an animation. While the covers fly, each slot a cover left shows a ghost of
/// it at `dimOpacity`, the same rule as during the carry, and the covers land
/// onto those ghosts.
///
/// Observation keeps redraws narrow. Each cell reads only its own `SlotState`,
/// so crossing a slot redraws two cells, not the grid. Only `FloatingCover`
/// reads `held` and `displaced`, which change on every finger move.
@Observable
final class SlotDrag {

    // MARK: - Motion constants
    //
    // Named so they can be tuned after a try on a device. Reduce Motion skips
    // the scale, the carry spring, the tilt and the flights, and fades instead.

    /// The ghost a lifted cover leaves in its slot, and how fast it dims: on
    /// lift for the held cover, and on release for the cover a drop displaces.
    static let dimOpacity = 0.3
    static let dimFade = Animation.easeOut(duration: 0.15)
    static let ghostFade = Animation.easeOut(duration: 0.12)
    /// After a move, the origin's ghost fades out over its grey square, then
    /// the square's plus fades in.
    static let ghostClear = Animation.easeOut(duration: 0.2)
    static let plusFade = Animation.easeOut(duration: 0.15)
    /// How long the displaced cover rises before it starts to settle.
    static let displacedRise: TimeInterval = 0.15

    /// The slot under the finger shrinks to the project's press scale.
    static let targetScale: CGFloat = 0.97
    static let targetSpring = Animation.spring(response: 0.2, dampingFraction: 1)

    /// Lift: the cover grows and its shadow fades in, overshooting.
    static let liftScale: CGFloat = 1.08
    static let liftSpring = Animation.spring(response: 0.35, dampingFraction: 0.45)
    static let shadowRadius: CGFloat = 12
    static let shadowY: CGFloat = 6
    static let shadowOpacity = 0.25

    /// Carry: the cover follows the finger through a soft spring, so it
    /// trails and wobbles a little when the finger stops, and leans into
    /// sideways movement.
    static let carrySpring = Animation.spring(response: 0.18, dampingFraction: 0.65)
    static let maxTilt: Double = 10
    /// Horizontal speed, in points per second, that earns the full tilt.
    static let fullTiltSpeed: CGFloat = 600
    /// Weight of each new velocity sample against the running value.
    static let velocitySmoothing: CGFloat = 0.3
    /// Applied to the velocity every tick the finger does not move.
    static let velocityDecay: CGFloat = 0.5

    /// Flight and landing, all started on release and run together: the
    /// cover travels critically damped, settles from `liftScale` to 1 with a
    /// small overshoot, and rocks back upright.
    static let flightSpring = Animation.spring(response: 0.3, dampingFraction: 1)
    static let landingSpring = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let tiltSettleSpring = Animation.spring(response: 0.35, dampingFraction: 0.5)

    /// Reduce Motion's replacement for all of the above.
    static let fade = Animation.easeOut(duration: 0.2)

    /// Edge scrolling: within this distance of a row's side, the row scrolls
    /// under a held cover, from 0 at the zone's inner edge up to this speed
    /// at the row's edge.
    static let autoScrollZone: CGFloat = 48
    static let autoScrollMaxSpeed: CGFloat = 400

    // MARK: - State

    /// A cover drawn above the rows.
    struct Floating {
        var album: Album
        var size: CGSize
        var center: CGPoint
        var lifted: Bool
        /// True while it follows the finger; its moves then go through the
        /// carry spring.
        var carried: Bool
        var tilt: Double
        var opacity: Double
    }

    /// True from lift to release.
    private(set) var isHeld = false

    /// The cover under the finger, and after release, the one flying to where
    /// it was dropped or back.
    private(set) var held: Floating?

    /// On a swap, the cover that was in the target slot, flying to the origin.
    private(set) var displaced: Floating?

    /// Bumped on every drop that changed the grid, for the landing haptic.
    private(set) var landings = 0

    /// The slot the held cover came from, and the slot under the finger.
    /// Not observed here: each is mirrored into that slot's `SlotState`.
    @ObservationIgnored private(set) var source: Int? {
        didSet { mirror(oldValue, source) { state, on in state.isSource = on } }
    }
    @ObservationIgnored private(set) var target: Int? {
        didSet { mirror(oldValue, target) { state, on in state.isTarget = on } }
    }

    /// Slot frames in `GridSpace`. Not observed: they change on every scroll
    /// frame and only the hit test reads them.
    @ObservationIgnored var frames: [Int: CGRect] = [:]

    /// The grid's own bounds in `GridSpace`.
    @ObservationIgnored var bounds: CGRect = .zero

    /// Where the grid's origin sits in window coordinates. The lift arrives
    /// from UIKit with the finger in window coordinates; this brings it into
    /// `GridSpace`.
    @ObservationIgnored var windowOrigin: CGPoint = .zero

    @ObservationIgnored private var states: [Int: SlotState] = [:]
    @ObservationIgnored private var inFlight: Set<Int> = []
    /// On a move, the origin, which clears softly once the cover has landed.
    @ObservationIgnored private var clearsAfterLanding: Int?
    @ObservationIgnored private var origin: CGPoint = .zero
    @ObservationIgnored private var finger: CGPoint?
    @ObservationIgnored private var heldLoop: Task<Void, Never>?
    @ObservationIgnored private var velocityX: CGFloat = 0
    @ObservationIgnored private var lastMove: (x: CGFloat, at: Date)?

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    /// Nothing held and nothing in flight, so a new cover may lift.
    private var isIdle: Bool { !isHeld && held == nil && displaced == nil }

    /// The state one cell reads. Made on first use.
    func state(for key: Int) -> SlotState {
        if let existing = states[key] { return existing }
        let made = SlotState()
        states[key] = made
        return made
    }

    private func mirror(_ old: Int?, _ new: Int?, _ set: (SlotState, Bool) -> Void) {
        guard old != new else { return }
        if let old { set(state(for: old), false) }
        if let new { set(state(for: new), true) }
    }

    /// What the two slots in a drop draw while the covers fly: what each held
    /// before the drop, the albums as ghosts and an empty target as empty.
    /// Read from the grid before the swap is written.
    static func landingOverrides(source: Int, target: Int,
                                 grid: [Int: Album?]) -> [Int: Album?] {
        var overrides: [Int: Album?] = [:]
        // updateValue, as in the view model: a literal `overrides[key] = nil`
        // would drop the key, and the empty target would repaint early.
        overrides.updateValue(grid[source] ?? nil, forKey: source)
        overrides.updateValue(grid[target] ?? nil, forKey: target)
        return overrides
    }

    // MARK: - The gesture's moments

    /// Picks up the cover in `key`. False when another cover is still held or
    /// in flight, or the slot has not reported a frame yet.
    @discardableResult
    func lift(_ key: Int, album: Album) -> Bool {
        guard isIdle, let frame = frames[key] else { return false }

        source = key
        isHeld = true
        origin = CGPoint(x: frame.midX, y: frame.midY)
        finger = origin
        velocityX = 0
        lastMove = nil
        held = Floating(album: album, size: frame.size, center: origin,
                        lifted: false, carried: true, tilt: 0, opacity: 1)

        if reduceMotion {
            held?.lifted = true
        } else {
            withAnimation(Self.liftSpring) { held?.lifted = true }
        }

        startHeldLoop()
        return true
    }

    /// The finger moved. `translation` is from where the press began, so the
    /// cover keeps the offset it was grabbed at. Written plainly: the floating
    /// cover's own carry spring retargets one running animation, rather than a
    /// new one starting on every touch event.
    func move(translation: CGSize, location: CGPoint) {
        guard isHeld else { return }
        let center = CGPoint(x: origin.x + translation.width, y: origin.y + translation.height)
        finger = location
        held?.center = center
        if !reduceMotion {
            track(x: center.x)
            let lean = tilt
            if abs(lean - (held?.tilt ?? 0)) > 0.05 { held?.tilt = lean }
        }
        retarget()
    }

    /// The finger lifted. Returns the slot the cover landed on, or nil when it
    /// goes back where it came from. The caller writes the grid; `grid` is
    /// what it held before, for the cover the drop displaces.
    func release(at location: CGPoint?, grid: [Int: Album?]) -> Int? {
        guard isHeld, let source else { return nil }

        stopHeldLoop()
        isHeld = false
        target = nil
        held?.carried = false

        let hit = location.flatMap(slot(at:))
        let landing = hit == source ? nil : hit

        if let landing {
            landings += 1
            fly(from: source, to: landing, grid: grid)
        } else {
            flyBack(to: source)
        }
        return landing
    }

    /// The system took the touch away mid-drag. Treated as a drop outside
    /// every slot: the cover goes back and nothing changes.
    func cancel(from key: Int) {
        guard isHeld, source == key else { return }
        _ = release(at: nil, grid: [:])
    }

    // MARK: - Hit testing

    func gridPoint(fromWindow point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - windowOrigin.x, y: point.y - windowOrigin.y)
    }

    private func slot(at point: CGPoint) -> Int? {
        frames.first { _, frame in frame.contains(point) }?.key
    }

    private func retarget() {
        let hit = finger.flatMap(slot(at:))
        let next = hit == source ? nil : hit
        if next != target { target = next }
    }

    // MARK: - Tilt

    private var tilt: Double {
        let lean = Double(velocityX / Self.fullTiltSpeed) * Self.maxTilt
        return min(max(lean, -Self.maxTilt), Self.maxTilt)
    }

    /// Folds the cover's new x into a smoothed horizontal velocity.
    private func track(x: CGFloat) {
        let now = Date()
        if let last = lastMove {
            let dt = now.timeIntervalSince(last.at)
            if dt > 0.001 {
                let sample = (x - last.x) / CGFloat(dt)
                velocityX += (sample - velocityX) * Self.velocitySmoothing
            }
        }
        lastMove = (x, now)
    }

    /// A finger that has stopped lets the cover straighten up.
    private func decayTilt(now: Date) {
        guard !reduceMotion, let last = lastMove,
              now.timeIntervalSince(last.at) > 0.05, abs(velocityX) > 1 else { return }
        velocityX *= Self.velocityDecay
        if abs(velocityX) < 5 { velocityX = 0 }
        held?.tilt = tilt
    }

    // MARK: - Flights

    /// A drop on another slot. The held cover flies there; on a swap the
    /// cover it displaces lifts off the target and flies to the origin at the
    /// same time. Both slots show ghosts of what they held until both covers
    /// have landed: the origin keeps the ghost it has had since the lift, and
    /// the target's cover fades to one behind its departing copy.
    private func fly(from source: Int, to landing: Int, grid: [Int: Album?]) {
        let into = frames[landing]
        let back = frames[source]

        guard !reduceMotion, let into, isVisible(into) else {
            fade()
            return
        }

        let overrides = Self.landingOverrides(source: source, target: landing, grid: grid)
        // A move: nothing comes back to the origin, so it ends empty.
        clearsAfterLanding = (grid[landing] ?? nil) == nil ? source : nil
        for (key, before) in overrides {
            inFlight.insert(key)
            if key == landing {
                withAnimation(Self.ghostFade) { state(for: key).override = .some(before) }
            } else {
                state(for: key).override = .some(before)
            }
        }

        // The copy starts exactly over the target's cover, at full size, so
        // nothing jumps as it appears; it rises as it departs.
        var rising = false
        if let back, isVisible(back), let album = grid[landing] ?? nil {
            displaced = Floating(album: album, size: into.size, center: center(of: into),
                                 lifted: false, carried: false, tilt: 0, opacity: 1)
            withAnimation(Self.liftSpring) { displaced?.lifted = true }
            rising = true
        }

        land(rising: rising) {
            self.held?.center = self.center(of: into)
            self.held?.size = into.size
            if let back {
                self.displaced?.center = self.center(of: back)
                self.displaced?.size = back.size
            }
        } settle: {
            self.held?.lifted = false
        } rock: {
            self.held?.tilt = 0
        }
    }

    /// A drop outside every slot, or on its own: the cover goes home. The
    /// origin stays dimmed until it arrives.
    private func flyBack(to source: Int) {
        guard !reduceMotion, let home = frames[source], isVisible(home) else {
            fade()
            return
        }
        land {
            self.held?.center = self.center(of: home)
            self.held?.size = home.size
        } settle: {
            self.held?.lifted = false
        } rock: {
            self.held?.tilt = 0
        }
    }

    /// Runs the flight, the landing settle and the tilt's rock back upright
    /// together, and finishes when all of them have come to rest. A displaced
    /// cover that is `rising` settles a beat later, once its rise has shown:
    /// set in the same update, the rise and the settle would cancel out.
    private func land(rising: Bool = false, _ flight: @escaping () -> Void,
                      settle: @escaping () -> Void, rock: @escaping () -> Void) {
        var running = rising ? 4 : 3
        let done = { [weak self] in
            running -= 1
            if running == 0 { self?.finish() }
        }
        withAnimation(Self.flightSpring, completionCriteria: .logicallyComplete, flight, completion: done)
        withAnimation(Self.landingSpring, completionCriteria: .logicallyComplete, settle, completion: done)
        withAnimation(Self.tiltSettleSpring, completionCriteria: .logicallyComplete, rock, completion: done)
        if rising {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.displacedRise) { [weak self] in
                withAnimation(Self.landingSpring, completionCriteria: .logicallyComplete,
                              { self?.displaced?.lifted = false }, completion: done)
            }
        }
    }

    /// Reduce Motion, or nowhere visible to fly to: the cover fades where it
    /// is and the grid shows its new state underneath.
    private func fade() {
        withAnimation(Self.fade) {
            held?.opacity = 0
            source = nil
        } completion: { [weak self] in
            self?.finish()
        }
    }

    /// Everything has landed. The floating covers go, and the ghosts under
    /// them switch to the grid's contents at full in the same frame, without
    /// animation, so nothing visible changes where a cover just came to rest.
    ///
    /// After a move the origin has nothing landing on it, so its ghost is not
    /// swapped out under a cover. It keeps its override here and clears
    /// softly in `clearGhost`.
    private func finish() {
        guard !isHeld else { return }
        let clearing = clearsAfterLanding
        clearsAfterLanding = nil

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            held = nil
            displaced = nil
            source = nil
            for key in inFlight where key != clearing { state(for: key).override = nil }
            inFlight = []
        }

        if let clearing { clearGhost(clearing) }
    }

    /// The ghost fades to nothing over the grey square, the cell becomes the
    /// empty square with its plus held back, and the plus fades in.
    private func clearGhost(_ key: Int) {
        let slot = state(for: key)
        withAnimation(Self.ghostClear) {
            slot.isClearing = true
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                slot.isPlusHidden = true
                slot.override = nil
                slot.isClearing = false
            }
            DispatchQueue.main.async {
                withAnimation(Self.plusFade) { slot.isPlusHidden = false }
            }
        }
    }

    private func isVisible(_ frame: CGRect) -> Bool {
        bounds.insetBy(dx: -1, dy: -1).contains(center(of: frame))
    }

    private func center(of frame: CGRect) -> CGPoint {
        CGPoint(x: frame.midX, y: frame.midY)
    }

    // MARK: - While held

    /// Runs every 0.1 s while a cover is held: straightens the tilt when the
    /// finger stops, and re-checks the slot under the finger, since a row
    /// scrolling under a still finger changes it. A few comparisons a tick;
    /// the edge scrolling itself runs per frame in `SlotPressSurface`.
    private func startHeldLoop() {
        heldLoop?.cancel()
        heldLoop = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.isHeld else { return }
                self.decayTilt(now: Date())
                self.retarget()
            }
        }
    }

    private func stopHeldLoop() {
        heldLoop?.cancel()
        heldLoop = nil
    }
}

/// The covers in motion, drawn above every row of the grid: the displaced one
/// underneath, the held one on top.
struct FloatingCover: View {
    let drag: SlotDrag

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let displaced = drag.displaced { FloatingCoverView(floating: displaced) }
            if let held = drag.held { FloatingCoverView(floating: held) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One cover in motion. Position and tilt change on every finger move; the
/// face underneath does not, so it is a separate view SwiftUI can skip.
private struct FloatingCoverView: View {
    let floating: SlotDrag.Floating

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FloatingCoverFace(album: floating.album, size: floating.size,
                          lifted: floating.lifted, reduceMotion: reduceMotion)
            .equatable()
            .rotationEffect(.degrees(floating.tilt))
            .opacity(floating.opacity)
            .position(floating.center)
            // While carried, every move and lean runs through the carry spring,
            // which retargets the animation already running.
            .transaction(value: floating.center) { transaction in
                if floating.carried && !reduceMotion { transaction.animation = SlotDrag.carrySpring }
            }
            .transaction(value: floating.tilt) { transaction in
                if floating.carried && !reduceMotion { transaction.animation = SlotDrag.carrySpring }
            }
    }
}

/// The cover itself, its shadow and its lift. The shadow's radius and offset
/// never change; only its opacity animates, and it is composited once with the
/// cover so scaling and rotating move a finished layer instead of redrawing a
/// blur every frame.
private struct FloatingCoverFace: View, Equatable {
    let album: Album
    let size: CGSize
    let lifted: Bool
    let reduceMotion: Bool

    var body: some View {
        AsyncAlbumSquare(album: album)
            .frame(width: size.width, height: size.height)
            .shadow(color: .black.opacity(lifted ? SlotDrag.shadowOpacity : 0),
                    radius: SlotDrag.shadowRadius, y: SlotDrag.shadowY)
            .compositingGroup()
            .scaleEffect(lifted && !reduceMotion ? SlotDrag.liftScale : 1)
    }
}
