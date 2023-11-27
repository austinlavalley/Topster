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

struct AnimatedSaveButtonView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    @State private var isAnimating = false
    @State private var isSuccess = false
    
    @State var buttonText: String
    @State var buttonActionText: String
    
    let isSecondaryStyle: Bool

    var body: some View {
        Button(action: {
            self.isAnimating = true
            self.isSuccess = true
            
            vm.addToSavedGrids(grid: vm.FortyGridDict)

            // After a delay, reset the animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring()) {
                    self.isAnimating = false
                }
            }
        }) {
            Label(isAnimating ? buttonActionText : buttonText, systemImage: isAnimating ? "checkmark" : "")
                .frame(maxWidth: .infinity)
                .foregroundColor(isSecondaryStyle ? Color.blue : Color.white)
                .bold()
                .padding()
                .background(isAnimating ? (isSecondaryStyle ? Color.gray.opacity(0.25) : Color.green) : (isSecondaryStyle ? Color.gray.opacity(0.25) : Color.blue))
                .cornerRadius(12)
        }
        .disabled(isAnimating) // Disable the button while animating
    }
}
