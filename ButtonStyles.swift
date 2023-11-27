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
