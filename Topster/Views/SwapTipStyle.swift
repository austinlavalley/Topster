//
//  SwapTipStyle.swift
//  Topster
//

import SwiftUI
import TipKit

/// The swap tip above the grid, in a row that opens and closes around it so
/// it arrives the way it leaves: a fade and a drop from the top on the
/// spring below, with the grid moving down to make room. Under Reduce Motion
/// it only fades, and the grid makes room without moving.
///
/// TipView draws its content in one frame when the tip becomes available,
/// and inserting a fresh TipView with a transition does not help, because it
/// starts empty and fills in a frame later. So the TipView stays in place
/// and the row's own height, clip and opacity do the motion, from the
/// height the tip measured.
///
/// A tip that becomes available while the add sheet is up, which is how the
/// second album usually lands, waits for the sheet to close and then
/// `arrivalDelay` more, so it arrives on a still grid instead of under the
/// sheet's exit. A tip already available at launch is simply there.
struct SwapTipRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    private let tip = SwapTip()

    /// TipKit says the tip may show.
    @State private var isAvailable: Bool
    /// The row takes the tip's height.
    @State private var isOpen: Bool
    /// The tip is drawn.
    @State private var isShown: Bool
    /// The tip's own height, kept after TipView empties itself on close so
    /// the row can close over it.
    @State private var tipHeight: CGFloat = 0
    /// A tip already available when the grid opens is simply there instead
    /// of sliding in, so its first measure lands without animation.
    @State private var openedAtLaunch: Bool

    private static let spring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    private static let fade = Animation.easeInOut(duration: 0.2)
    /// After the add sheet closes, about as long as its exit takes.
    static let arrivalDelay: Double = 0.45

    init() {
        let available = SwapTip().shouldDisplay
        _isAvailable = State(initialValue: available)
        _isOpen = State(initialValue: available)
        _isShown = State(initialValue: available)
        _openedAtLaunch = State(initialValue: available)
    }

    var body: some View {
        TipView(tip)
            .tipViewStyle(SwapTipStyle())
            .padding(.horizontal)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                measured(height)
            }
            .opacity(isShown ? 1 : 0)
            // Pinned to the bottom, so the tip comes down from the top as
            // the row opens and goes up as it closes.
            .frame(height: isOpen ? tipHeight : 0, alignment: .bottom)
            .clipped()
            .allowsHitTesting(isShown)
            .task {
                for await status in tip.statusUpdates {
                    isAvailable = status == .available
                }
            }
            // Closing is immediate. Arriving waits for the add sheet to be
            // closed, then arrivalDelay; reopening the sheet in that time
            // cancels the wait, which starts again once it closes.
            .task(id: [isAvailable, vm.showSearchSheet]) {
                guard isAvailable else {
                    show(false)
                    return
                }
                guard !isOpen, !vm.showSearchSheet else { return }
                try? await Task.sleep(for: .seconds(Self.arrivalDelay))
                guard !Task.isCancelled, isAvailable else { return }
                show(true)
            }
            .featureTipTracking(tip, as: .swap)
    }

    private func measured(_ height: CGFloat) {
        // An empty TipView measures 0: before the tip is available, and
        // straight after a close, while the row is still closing over it.
        guard height > 0, height != tipHeight else { return }
        if openedAtLaunch || !isOpen || reduceMotion {
            openedAtLaunch = false
            tipHeight = height
        } else {
            withAnimation(Self.spring) { tipHeight = height }
        }
    }

    private func show(_ available: Bool) {
        guard available != isOpen || available != isShown else { return }
        if !reduceMotion {
            withAnimation(Self.spring) {
                isOpen = available
                isShown = available
            }
        } else if available {
            isOpen = true
            withAnimation(Self.fade) { isShown = true }
        } else {
            withAnimation(Self.fade) {
                isShown = false
            } completion: {
                isOpen = false
            }
        }
    }
}

/// The swap tip's layout: a small looping drawing of the gesture beside the
/// tip's title and close control. Used for `SwapTip` only; the other tips
/// keep TipKit's default style.
///
/// A custom style replaces TipKit's whole layout, so the title, the close
/// control and what closing does are rebuilt here to match the default:
/// the tip's own title in headline, a secondary xmark in the top corner, and
/// a close that invalidates with `.tipClosed`, which is what TipKit records
/// and what `featureTipTracking` reports as dismissed.
struct SwapTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 12) {
            SwapIllustration()

            configuration.tip.title
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                configuration.tip.invalidate(reason: .tipClosed)
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // TipView replaces its children's identifiers with "TipView",
            // so the label is what tests and VoiceOver find.
            .accessibilityLabel("Close")
        }
        // The tip's corners are nearly round on iOS 26, so the drawing
        // sits 16 pt in. 10 pt above and below keeps the row within a
        // point of TipKit's default single-line tip (64 pt).
        .padding(.vertical, 10)
        .padding(.leading, 16)
        .padding(.trailing, 6)
    }
}


/// A 3 by 3 field of slots with one album sliding from the top-left slot to
/// the bottom-right one, on the swap's own springs: it lifts to the swap's
/// scale, travels, lands, holds, and starts again. Under Reduce Motion it
/// sits in the bottom-right slot and does not move.
struct SwapIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var atEnd = false
    @State private var lifted = false
    @State private var visible = true

    /// About 45 pt across, so the drawing clears the tip's rounded corners
    /// and the row stays near TipKit's own single-line height.
    private static let cell: CGFloat = 11.2
    private static let gap: CGFloat = 5.6
    private static let radius: CGFloat = 2.4
    private static let side = cell * 3 + gap * 2
    /// From the top-left slot to the bottom-right one, on both axes.
    private static let travel = (cell + gap) * 2

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: Self.gap) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: Self.gap) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: Self.radius)
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(width: Self.cell, height: Self.cell)
                        }
                    }
                }
            }

            RoundedRectangle(cornerRadius: Self.radius)
                .fill(.secondary)
                .frame(width: Self.cell, height: Self.cell)
                .scaleEffect(lifted ? SlotDrag.liftScale : 1)
                .offset(x: atEnd ? Self.travel : 0, y: atEnd ? Self.travel : 0)
                .opacity(visible ? 1 : 0)
        }
        .frame(width: Self.side, height: Self.side)
        .accessibilityHidden(true)
        .task(id: reduceMotion) {
            guard !reduceMotion else {
                atEnd = true
                lifted = false
                visible = true
                return
            }
            await loop()
        }
    }

    /// One cycle every 1.6 s: appear 0.15, lift and travel 0.45, land and
    /// hold 0.6, fade 0.4.
    private func loop() async {
        while !Task.isCancelled {
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                atEnd = false
                lifted = false
                visible = false
            }
            withAnimation(.easeOut(duration: 0.15)) { visible = true }
            guard await pause(0.15) else { return }

            withAnimation(SlotDrag.liftSpring) { lifted = true }
            withAnimation(SlotDrag.flightSpring) { atEnd = true }
            guard await pause(0.45) else { return }

            withAnimation(SlotDrag.landingSpring) { lifted = false }
            guard await pause(0.6) else { return }

            withAnimation(.easeOut(duration: 0.15)) { visible = false }
            guard await pause(0.4) else { return }
        }
    }

    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))) != nil
    }
}
