//
//  GridSlotCell.swift
//  Topster
//

import SwiftUI
import UIKit

/// One slot of the interactive grid: the cover, or the grey placeholder with a plus.
/// Every row of every layout in GridContent draws its cells through this and sets
/// its own frame around it. The export in RenderView draws its own cells on purpose.
///
/// Also the one place the drag-to-swap gesture lives. Hold a cover for 0.4 s and it
/// lifts into `SlotDrag`'s floating copy, which follows the finger above the rows;
/// this cell stays put, a ghost at 30%, until a cover lands on it. A plain tap still opens
/// search. Empty slots cannot be lifted but are drop targets.
struct GridSlotCell: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    /// Nil outside GridContent, which leaves the cell tap-only.
    @Environment(SlotDrag.self) private var drag: SlotDrag?

    let key: Int
    let album: Album?

    /// This slot's own drag state. Reading only this, and not the drag's
    /// shared properties, is what keeps a drag from redrawing every cell.
    private var state: SlotState? { drag?.state(for: key) }
    private var isSource: Bool { state?.isSource ?? false }
    private var isTarget: Bool { state?.isTarget ?? false }
    private var isClearing: Bool { state?.isClearing ?? false }

    private enum Shown {
        case album(Album, ghost: Bool)
        case empty
    }

    /// The grid's contents, unless covers are in flight to or from this slot:
    /// then what it held before the drop, an album as a ghost.
    private var shown: Shown {
        if let override = state?.override {
            return override.map { album in .album(album, ghost: true) } ?? .empty
        }
        return album.map { album in .album(album, ghost: false) } ?? .empty
    }

    var body: some View {
        slot
            // The quiet target state: the project's press scale.
            .scaleEffect(isTarget ? SlotDrag.targetScale : 1)
            .animation(SlotDrag.targetSpring, value: isTarget)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(key: SlotFramesKey.self,
                                           value: [key: geometry.frame(in: .named(GridSpace.name))])
                }
            }
            .id(key)
    }

    @ViewBuilder private var slot: some View {
        switch shown {
        case .album(let album, let ghost):
            cover(album, ghost: ghost)
        case .empty:
            // A Button for the press-down, so an empty slot gives way under the
            // finger like the app's other controls. A drag that starts here
            // still scrolls the row.
            Button { select() } label: {
                EmptySlotFace(isPlusHidden: state?.isPlusHidden == true)
            }
            .buttonStyle(PressScale())
            .accessibilityIdentifier("slot-\(key)")
            .accessibilityLabel("Empty slot")
        }
    }

    @ViewBuilder private func cover(_ album: Album, ghost: Bool) -> some View {
        let square = AsyncAlbumSquare(album: album)
            .opacity(isClearing ? 0 : isSource || ghost ? SlotDrag.dimOpacity : 1)
            .animation(SlotDrag.dimFade, value: isSource)
            // The empty square a ghost clears to, faded in under it after a
            // move. Invisible otherwise, and behind an opaque cover.
            .background {
                // Plus held back here; it fades in once the cell is empty.
                EmptySlotFace(isPlusHidden: true)
                    .opacity(isClearing ? 1 : 0)
            }
            // VoiceOver's way to move an album, since it cannot drag: one slot
            // back or forward, swapping with whatever is there, as a drop does.
            // The slot number is the value, so the label the tests find slots
            // by stays "<name>, <artist>".
            .accessibilityValue("slot \(key)")
            .accessibilityActions {
                if let previous = SlotStep.neighbour(of: key, by: -1, slotCount: vm.activeGridType.slotCount) {
                    Button("Move to previous slot") { move(to: previous) }
                }
                if let next = SlotStep.neighbour(of: key, by: 1, slotCount: vm.activeGridType.slotCount) {
                    Button("Move to next slot") { move(to: next) }
                }
            }

        if let drag {
            // Taps and holds both arrive through UIKit here. A recognizer only
            // sees touches that land on its view, so the surface cannot pass
            // taps through to SwiftUI; it forwards them instead. VoiceOver
            // activation goes through the accessibility action.
            // The identifier goes on before the overlay, which is hidden from
            // accessibility, so each slot is still one element.
            square
                .accessibilityIdentifier("slot-\(key)")
                .accessibilityLabel("\(album.name), \(album.artist)")
                .accessibilityAction { select() }
                .overlay {
                    SlotPressSurface(onTap: select) { phase, window, translation in
                        press(phase, window: window, translation: translation, album: album, drag: drag)
                    }
                    .accessibilityHidden(true)
                }
        } else {
            square
                .accessibilityIdentifier("slot-\(key)")
                .accessibilityLabel("\(album.name), \(album.artist)")
                .onTapGesture { select() }
        }
    }

    private func select() {
        vm.selectedGridID = key
        vm.toggleSheet()
    }

    /// The accessibility move. No flight: the grid changes and VoiceOver says
    /// where the album went. Posted a beat later, because VoiceOver re-reads
    /// the focused slot when its album changes and would talk over it.
    private func move(to neighbour: Int) {
        vm.swapSlots(key, neighbour)
        let announcement = SlotStep.announcement(movedTo: neighbour)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    /// The long press's four moments, from UIKit: lift, move, drop, cancel.
    private func press(_ phase: UIGestureRecognizer.State, window: CGPoint, translation: CGSize,
                       album: Album, drag: SlotDrag) {
        let location = drag.gridPoint(fromWindow: window)

        switch phase {
        case .began:
            drag.lift(key, album: album)
        case .changed:
            guard drag.source == key else { return }
            drag.move(translation: translation, location: location)
        case .ended:
            guard drag.isHeld, drag.source == key else { return }
            // The grid as it is before the swap, for the cover the drop
            // displaces. The write itself is immediate.
            if let landing = drag.release(at: location, grid: vm.FortyGridDict) {
                vm.swapSlots(key, landing)
            }
        case .cancelled, .failed:
            drag.cancel(from: key)
        default:
            break
        }
    }
}

/// The empty slot, and the square a ghost clears to after a move, so the two
/// always match. Tertiary fill and label are Apple's own colours for empty
/// controls and adapt to light and dark grounds. The old `.secondary` fill
/// was judged too loud next to covers on 30 Sep 2026.
private struct EmptySlotFace: View {
    let isPlusHidden: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(uiColor: .tertiarySystemFill))
            Image(systemName: "plus").bold().foregroundColor(Color(uiColor: .tertiaryLabel))
                .opacity(isPlusHidden ? 0 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// The arithmetic behind the VoiceOver move actions.
enum SlotStep {

    /// The slot `step` away from `key`, or nil when that is off either end of
    /// the layout, in which case the action is not offered.
    static func neighbour(of key: Int, by step: Int, slotCount: Int) -> Int? {
        let next = key + step
        return (1...max(slotCount, 1)).contains(next) ? next : nil
    }

    static func announcement(movedTo key: Int) -> String {
        "Moved to slot \(key)"
    }
}

/// A clear UIKit surface over a cover that carries the tap, the lift, and the
/// edge scrolling while the cover is held.
///
/// The lift is a `UILongPressGestureRecognizer`, not a SwiftUI gesture. On an
/// iPhone the SwiftUI version, a long press sequenced before a drag, took every
/// touch that landed on a cover, so neither the rows nor the page would scroll
/// from one. The UIKit recognizer coexists with `UIScrollView`'s pan the way
/// UICollectionView's reordering does: a finger that moves before 0.4 s is the
/// scroll view's, and once the press fires the scroll view cannot start.
private struct SlotPressSurface: UIViewRepresentable {
    var onTap: () -> Void
    /// State, finger in window coordinates, and distance from where the press began.
    var onPress: (UIGestureRecognizer.State, CGPoint, CGSize) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onPress: onPress)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.tapped(_:)))
        let press = UILongPressGestureRecognizer(target: context.coordinator,
                                                 action: #selector(Coordinator.pressed(_:)))
        press.minimumPressDuration = 0.4
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(press)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onPress = onPress
    }

    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) {
        coordinator.stopEdgeScroll()
    }

    final class Coordinator: NSObject {
        var onTap: () -> Void
        var onPress: (UIGestureRecognizer.State, CGPoint, CGSize) -> Void
        private var start: CGPoint = .zero
        private var finger: CGPoint = .zero
        private weak var window: UIWindow?
        private var link: CADisplayLink?

        init(onTap: @escaping () -> Void,
             onPress: @escaping (UIGestureRecognizer.State, CGPoint, CGSize) -> Void) {
            self.onTap = onTap
            self.onPress = onPress
        }

        deinit {
            link?.invalidate()
        }

        @objc func tapped(_ recognizer: UITapGestureRecognizer) {
            if recognizer.state == .ended { onTap() }
        }

        @objc func pressed(_ recognizer: UILongPressGestureRecognizer) {
            let location = recognizer.location(in: nil)
            finger = location

            switch recognizer.state {
            case .began:
                start = location
                window = recognizer.view?.window
                startEdgeScroll()
            case .ended, .cancelled, .failed:
                stopEdgeScroll()
            default:
                break
            }

            onPress(recognizer.state, location,
                    CGSize(width: location.x - start.x, height: location.y - start.y))
        }

        // MARK: Edge scrolling

        /// Every frame while held: if the finger is near a side of the row
        /// under it, that row scrolls, faster the closer the finger is to the
        /// edge. The row is found in the view tree, so it is whichever row
        /// the finger is over, not the one the cover came from.
        private func startEdgeScroll() {
            stopEdgeScroll()
            let link = CADisplayLink(target: self, selector: #selector(step(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stopEdgeScroll() {
            link?.invalidate()
            link = nil
        }

        @objc private func step(_ link: CADisplayLink) {
            guard let window, let row = row(at: finger, in: window) else { return }

            let frame = row.convert(row.bounds, to: nil)
            let zone = SlotDrag.autoScrollZone
            let fromLeft = finger.x - frame.minX
            let fromRight = frame.maxX - finger.x

            let velocity: CGFloat
            if fromRight < zone {
                velocity = speed(atDistance: fromRight)
            } else if fromLeft < zone {
                velocity = -speed(atDistance: fromLeft)
            } else {
                return
            }

            let elapsed = CGFloat(link.targetTimestamp - link.timestamp)
            let least = -row.adjustedContentInset.left
            let most = max(least, row.contentSize.width - row.bounds.width + row.adjustedContentInset.right)
            let next = min(max(row.contentOffset.x + velocity * elapsed, least), most)
            if abs(next - row.contentOffset.x) > 0.01 {
                row.contentOffset.x = next
            }
        }

        /// 0 at the zone's inner edge, rising to the full speed at the row's
        /// edge and beyond it.
        private func speed(atDistance distance: CGFloat) -> CGFloat {
            let closeness = 1 - max(0, distance) / SlotDrag.autoScrollZone
            return SlotDrag.autoScrollMaxSpeed * min(max(closeness, 0), 1)
        }

        /// The horizontal scroll view under `point`. A finger just past a
        /// row's end, over the grid's margin, still counts: the point is moved
        /// toward the middle of the screen and tried again.
        private func row(at point: CGPoint, in window: UIWindow) -> UIScrollView? {
            if let row = horizontalScrollView(at: point, in: window) { return row }
            let inward = point.x < window.bounds.midX ? 24.0 : -24.0
            return horizontalScrollView(at: CGPoint(x: point.x + inward, y: point.y), in: window)
        }

        private func horizontalScrollView(at point: CGPoint, in window: UIWindow) -> UIScrollView? {
            var view = window.hitTest(point, with: nil)
            while let current = view {
                if let scroll = current as? UIScrollView,
                   scroll.contentSize.width > scroll.bounds.width + 0.5 {
                    return scroll
                }
                view = current.superview
            }
            return nil
        }
    }
}
