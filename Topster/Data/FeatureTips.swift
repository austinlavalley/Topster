//
//  FeatureTips.swift
//  Topster
//

import SwiftUI
import TipKit

/// One line about the swap, for people who already have albums down and
/// have never moved one. 1.8.0 shipped the swap without telling anyone.
struct SwapTip: Tip {
    /// Albums on the working grid now, kept current by the view model.
    @Parameter static var placedAlbums: Int = 0
    /// Set by the first swap, which also retires the tip.
    @Parameter static var hasSwapped: Bool = false

    var title: Text { Text("Hold an album to move it") }

    var rules: [Rule] {
        [
            #Rule(Self.$placedAlbums) { placed in placed >= 2 },
            #Rule(Self.$hasSwapped) { swapped in swapped == false },
        ]
    }
}

/// Setup and the `feature_tip` events for the swap tip.
enum FeatureTips {

    /// Call once at launch, after the UI-test reset and before any view.
    ///
    /// Debug builds read three launch flags. `-showAllTips YES` starts from
    /// an empty tip store and shows every tip regardless of its rules, for
    /// screenshots. `-resetTips YES` starts from an empty tip store and
    /// leaves the rules in charge, for testing the path people get.
    /// `-hideAllTips YES` shows none, for every other UI suite, which tap
    /// fixed points and would otherwise land on a tip that their own steps
    /// made eligible.
    static func configure(defaults: UserDefaults = .standard) {
        #if DEBUG
        if defaults.bool(forKey: "showAllTips") {
            try? Tips.resetDatastore()
            Tips.showAllTipsForTesting()
        } else if defaults.bool(forKey: "resetTips") {
            try? Tips.resetDatastore()
        } else if defaults.bool(forKey: "hideAllTips") {
            Tips.hideAllTipsForTesting()
        }
        #endif
        try? Tips.configure([.displayFrequency(.immediate)])
    }

    /// The person did what a tip describes: the first swap. Retires the tip
    /// and sends `acted` once per install, however often the action repeats.
    static func acted(_ feature: FeatureTipName, defaults: UserDefaults = .standard) {
        switch feature {
        case .swap: SwapTip.hasSwapped = true
        }

        let key = "featureTip.acted.\(feature.rawValue)"
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        Analytics.track(.featureTip(feature: feature, action: .acted))
    }
}


extension View {
    /// Sends `shown` when `tip` becomes available while this view is on
    /// screen, and `dismissed` when its close control retires it. A tip
    /// already closed when the view appears sends nothing.
    func featureTipTracking<T: Tip>(_ tip: T, as feature: FeatureTipName) -> some View {
        task {
            var wasAvailable = false
            for await status in tip.statusUpdates {
                switch status {
                case .available where !wasAvailable:
                    Analytics.track(.featureTip(feature: feature, action: .shown))
                case .invalidated(.tipClosed) where wasAvailable:
                    Analytics.track(.featureTip(feature: feature, action: .dismissed))
                default:
                    break
                }
                wasAvailable = status == .available
            }
        }
    }
}
