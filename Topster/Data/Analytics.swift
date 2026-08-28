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
    case gridSaved(layout: String)
    case layoutSelected(layout: String)

    /// The export funnel: previewed is the sheet opening, saved is the image
    /// actually written. The gap between them is the number that settles
    /// whether the "Export" wording confuses people.
    case exportPreviewed(layout: String)
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
        case let .gridSaved(layout), let .layoutSelected(layout),
             let .exportPreviewed(layout), let .exportSaved(layout):
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
