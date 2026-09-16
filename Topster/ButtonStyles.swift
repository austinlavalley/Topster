//
//  ButtonStyles.swift
//  Topster
//
//  Created by Austin Lavalley on 11/27/23.
//

import SwiftUI
import Foundation


struct DefaultPrimary: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            .bold()
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
    }
}


struct DefaultSecondary: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.accentColor)
            .bold()
            .padding()
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(12)
    }
}




/// What a confirming button is showing about the last thing it did.
enum ConfirmPhase: Equatable {
    case idle
    case confirmed
    case failed
}

/// A primary button that reports its own outcome in place.
///
/// The app's one confirmation pattern, used by Save grid and Save to Photos.
/// There is no system toast on iOS, and Apple's own apps confirm a completed
/// action in the control that caused it (Music's add button turning into a
/// checkmark, the App Store's Get becoming Open), with the success haptic on
/// the same frame. A floating pill over the controls was tried on the export
/// sheet and covered the options that had just been used.
///
/// The owner drives `phase`: set it to `.confirmed` or `.failed` when the
/// outcome is actually known, not on the tap. The button plays the haptic,
/// shows the state, and returns itself to `.idle` after a beat. Motion is a
/// critically damped spring: the change was not thrown, so it does not bounce.
struct ConfirmingButton: View {
    let title: String
    let confirmedTitle: String
    var failedTitle = "Try again"
    var isDisabled = false
    @Binding var phase: ConfirmPhase
    let action: () -> Void

    private var label: String {
        switch phase {
        case .idle: return title
        case .confirmed: return confirmedTitle
        case .failed: return failedTitle
        }
    }

    private var symbol: String? {
        switch phase {
        case .idle: return nil
        case .confirmed: return "checkmark"
        case .failed: return "exclamationmark.triangle"
        }
    }

    private var ground: Color {
        if isDisabled { return Color.gray.opacity(0.2) }
        switch phase {
        case .idle: return .blue
        case .confirmed: return .green
        case .failed: return .red
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(label)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isDisabled ? Color.gray : Color.white)
            .bold()
            .padding()
            .background(ground)
            .cornerRadius(12)
        }
        .buttonStyle(PressScale())
        .disabled(isDisabled || phase != .idle)
        .animation(.spring(response: 0.3, dampingFraction: 1), value: phase)
        .sensoryFeedback(.success, trigger: phase) { _, new in new == .confirmed }
        .sensoryFeedback(.error, trigger: phase) { _, new in new == .failed }
        .onChange(of: phase) { _, new in
            guard new != .idle else { return }
            // A failure stays a beat longer, since it carries words to read.
            let hold: Duration = new == .failed ? .seconds(2.5) : .seconds(1.5)
            Task { @MainActor in
                try? await Task.sleep(for: hold)
                if phase == new { phase = .idle }
            }
        }
    }
}

/// Press feedback on pointer-down, the way a real control gives it. 0.97 is
/// the project's press scale; keep every pressable on it.
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 1), value: configuration.isPressed)
    }
}

/// Save grid: the confirming button with the grid view's rules for when
/// there is nothing to save.
struct AnimatedSaveButtonView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    @State private var phase = ConfirmPhase.idle

    private var isDisabled: Bool {
        (vm.FortyGridDict.allSatisfy({ $0.value == nil }) || vm.currentActiveGrid != nil) && phase == .idle
    }

    var body: some View {
        ConfirmingButton(title: "Save grid", confirmedTitle: "Saved",
                         isDisabled: isDisabled, phase: $phase) {
            vm.addToSavedGrids()
            phase = .confirmed
        }
    }
}
