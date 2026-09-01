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
    @Environment(\.scenePhase) private var scenePhase
    
    @State var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")


    init() {
        Self.configureImageCache()
        Analytics.start()
    }

    /// Album art is ~72 KB a cover and Last.fm serves it with a ten year
    /// `Cache-Control: max-age`, but `URLCache.shared` defaults to 500 KB of memory.
    /// That is six covers. A forty album grid needs about 2.9 MB, so almost every
    /// cover was evicted the moment it arrived and refetched on the next scroll.
    private static func configureImageCache() {
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024,
                                   diskCapacity: 200 * 1024 * 1024,
                                   diskPath: "topster-art")
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(NotificationSettings(isEnabled: notificationsEnabled))
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                // One session_outcome per foreground stretch. Without it the
                // shortest sessions send nothing at all, so the people who
                // open the app and leave are invisible rather than merely
                // quiet. `.inactive` is ignored: a notification banner or a
                // pull of Control Center is not the end of a session.
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        Analytics.beginSession()
                    case .background:
                        Analytics.endSession(
                            gridFilled: vm.FortyGridDict.values.compactMap { entry in entry }.count)
                    default:
                        break
                    }
                }
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

