//
//  Analytics.swift
//  Topster
//

import Foundation
import os
import AmplitudeSwift

/// Every analytics event the app can emit, typed so call sites cannot invent
/// names or misspell properties, and so the entire taxonomy is reviewable in
/// this one file.
///
/// Nothing a user typed or listened to ever leaves the device. Events carry
/// counts, positions, and layout names only; search query text in particular
/// is deliberately absent.
enum AnalyticsEvent {

    /// A search finished and results are on screen. Counts only.
    case searchSettled(results: Int, backfills: Int, hintArrived: Bool,
                       cacheHits: Int, throttled: Bool)

    /// An album was placed on the grid from search: the 1-based position it
    /// held in the results, and whether Deezer discovery surfaced it. This is
    /// the metric that grades the 1.6.0 ranking work: taps clustering low mean
    /// the ranking is doing its job.
    case albumPlaced(position: Int, backfilled: Bool)

    /// The search sheet closed without placing anything, after this many
    /// settled searches. The counterpart to albumPlaced: the direct measure of
    /// search failing someone's intent.
    case searchAbandoned(searches: Int)

    case albumRemoved

    /// A grid was saved. `saved_grids` is how many the library holds afterwards,
    /// so the spread of that number across users is what any argument about
    /// capping saved grids has to be built on. It counts what is held rather
    /// than what was ever created, so deleting a grid lowers the next event's
    /// number.
    case gridSaved(layout: String, savedGrids: Int)
    case layoutSelected(layout: String)

    /// The export funnel: previewed is the sheet opening, attempted is the
    /// Save to Photos tap, saved is the image actually written.
    ///
    /// `filled` is how many slots held an album when the sheet opened. Previews
    /// bunched at low fill would mean people open the sheet to find out what it
    /// does, meet a half-empty grid and close it. That is a different problem
    /// from the Export wording losing them, and the two were indistinguishable.
    ///
    /// Attempted exists because without it, never tapping Save, denying the
    /// Photos permission, and a write that failed all look identical: the
    /// saved event only fires on success.
    case exportPreviewed(layout: String, filled: Int)
    case exportSaveAttempted(layout: String)
    case exportSaved(layout: String)

    /// A cover fetch ended without an image. Confirmed dead means the server
    /// said the art no longer exists; otherwise the attempts were exhausted
    /// and the cell keeps retrying. Real-world telemetry on CDN weather.
    case coverFetchFailed(confirmedDead: Bool)

    var name: String {
        switch self {
        case .searchSettled: return "search_settled"
        case .albumPlaced: return "album_placed"
        case .searchAbandoned: return "search_abandoned"
        case .albumRemoved: return "album_removed"
        case .gridSaved: return "grid_saved"
        case .layoutSelected: return "layout_selected"
        case .exportPreviewed: return "export_previewed"
        case .exportSaveAttempted: return "export_save_attempted"
        case .exportSaved: return "export_saved"
        case .coverFetchFailed: return "cover_fetch_failed"
        }
    }

    var properties: [String: Any] {
        switch self {
        case let .searchSettled(results, backfills, hintArrived, cacheHits, throttled):
            return ["results": results,
                    "backfills": backfills,
                    "hint_arrived": hintArrived,
                    "cache_hits": cacheHits,
                    "throttled": throttled]
        case let .albumPlaced(position, backfilled):
            return ["position": position, "backfilled": backfilled]
        case let .searchAbandoned(searches):
            return ["searches": searches]
        case .albumRemoved:
            return [:]
        case let .exportPreviewed(layout, filled):
            return ["layout": layout, "filled": filled]
        case let .gridSaved(layout, savedGrids):
            return ["layout": layout, "saved_grids": savedGrids]
        case let .layoutSelected(layout),
             let .exportSaveAttempted(layout), let .exportSaved(layout):
            return ["layout": layout]
        case let .coverFetchFailed(confirmedDead):
            return ["confirmed_dead": confirmedDead]
        }
    }
}


/// The one place the app talks to Amplitude.
///
/// Kept behind this facade so call sites stay one typed line, events are
/// testable without a network, and the SDK is swappable without touching
/// twenty files. Configured with Amplitude's default random device id and no
/// ad identifiers: no consent banner, no App Tracking Transparency prompt,
/// and the App Privacy label declares an anonymous device id and product
/// interaction only.
enum Analytics {

    private static let log = Logger(subsystem: "com.austinlavalley.Topster",
                                    category: "analytics")

    /// Client-side analytics keys ship inside every binary; this is not a
    /// secret in the Secrets.plist sense.
    private static let apiKey = "8ec595b3385ec444833d440a89a6fa16"

    private static var amplitude: Amplitude?

    /// Call once at launch.
    static func start() {
        let amplitude = Amplitude(configuration: Configuration(apiKey: apiKey))

        // Debug and simulator sessions reach the same dashboard but carry a
        // build property, so development noise is one filter away from gone.
        let identify = Identify()
        #if DEBUG
        identify.set(property: "build", value: "debug")
        #else
        identify.set(property: "build", value: "release")
        #endif
        amplitude.identify(identify: identify)

        Self.amplitude = amplitude
    }

    static func track(_ event: AnalyticsEvent) {
        log.notice("\(event.name, privacy: .public)")
        amplitude?.track(eventType: event.name, eventProperties: event.properties)
    }
}
