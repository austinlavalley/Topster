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
    
    @State var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")



    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(NotificationSettings(isEnabled: notificationsEnabled))
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}



final class NotificationSettings: ObservableObject {
    @State private var notificationPermsEnabled = UserDefaults.standard.bool(forKey: "isNotificationEnabled")

    @Published var isEnabled: Bool {
        didSet {
            if !notificationPermsEnabled {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        UserDefaults.standard.set(true, forKey: "isNotificationEnabled")
                        self.notificationPermsEnabled = true
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

