//
//  TopsterApp.swift
//  Topster
//
//  Created by Austin Lavalley on 8/27/23.
//

import SwiftUI

@main
struct TopsterApp: App {
    @StateObject private var vm = FortyScrollGridViewModel()
    @AppStorage("appColorTheme") private var darkModeEnabled = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
