//
//  SwapTipStyle.swift
//  Topster
//

import SwiftUI
import TipKit

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
        .padding(.vertical, 12)
        .padding(.leading, 12)
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

    private static let cell: CGFloat = 14
    private static let gap: CGFloat = 7
    private static let side = cell * 3 + gap * 2
    /// From the top-left slot to the bottom-right one, on both axes.
    private static let travel = (cell + gap) * 2

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: Self.gap) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: Self.gap) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(width: Self.cell, height: Self.cell)
                        }
                    }
                }
            }

            RoundedRectangle(cornerRadius: 3)
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
