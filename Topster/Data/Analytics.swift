//
//  Analytics.swift
//  Topster
//

import Foundation
import os
import AmplitudeSwift

/// Where a placed album came from. A fixed vocabulary rather than free text,
/// and the axis that will grade onboarding against plain search once the
/// onboarding work lands.
enum PlacementSource: String {
    case search
    case onboarding
    case suggestion
}


/// Every analytics event the app can emit, typed so call sites cannot invent
/// names or misspell properties, and so the entire taxonomy is reviewable in
/// this one file.
///
/// Nothing a user typed or listened to ever leaves the device. Events carry
/// counts, positions, layout names and flags only; search query text in
/// particular is deliberately absent, and `AnalyticsEventTests` enforces it.
enum AnalyticsEvent {

    /// The search sheet appeared. Untracked until now, which left the opening
    /// minute of a first session dark: opening the sheet and closing it
    /// without typing emitted nothing at all.
    ///
    /// `grid_filled` separates the first tap on an empty grid from the
    /// thirtieth tap on a nearly full one. `is_replacement` marks a slot that
    /// already held an album, which is the swap flow, not the build flow.
    case searchOpened(gridFilled: Int, isReplacement: Bool)

    /// A search finished and results are on screen.
    ///
    /// The three query properties are shape, never content. Length and word
    /// count separate "typed three characters and gave up" from "typed a full
    /// artist and album and got nothing". `is_refinement` marks a query that
    /// grew out of the previous one, which is the difference between a
    /// ranking that buried the album and a catalogue that never had it.
    case searchSettled(results: Int, backfills: Int, hintArrived: Bool,
                       cacheHits: Int, throttled: Bool,
                       queryLength: Int, wordCount: Int, isRefinement: Bool)

    /// An album was placed on the grid: the 1-based position it held in the
    /// results, whether Deezer discovery surfaced it, and which surface
    /// offered it. This is the metric that grades the 1.6.0 ranking work:
    /// taps clustering low mean the ranking is doing its job.
    case albumPlaced(position: Int, backfilled: Bool, source: PlacementSource)

    /// The search sheet closed without placing anything. The direct measure of
    /// search failing someone's intent.
    ///
    /// It used to fire only when at least one search had fully succeeded, so
    /// the three purest failures were silent: typing nothing, closing while a
    /// request was still in flight, and every search erroring out. That last
    /// one made a user on a dead connection look exactly like a user who never
    /// opened the sheet. `typed` and `failed_searches` tell them apart, and
    /// `searches` keeps its old meaning of searches that settled.
    case searchAbandoned(searches: Int, failedSearches: Int, typed: Bool)

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

    /// A once-per-install milestone, with what it cost to reach. Amplitude can
    /// derive a first occurrence on its own, but not the time and the session
    /// number it took to get there, and that is the part that says where
    /// people fall out.
    case activated(milestone: ActivationMilestone, secondsSinceInstall: Int, sessionNumber: Int)

    /// One event per foreground session, sent at background. The only event a
    /// bounced session produces, and the one that turns long and short
    /// sessions into a single readable distribution.
    case sessionOutcome(albumsPlaced: Int, gridFilled: Int, searchesOpened: Int,
                        saved: Bool, exported: Bool,
                        seconds: Int, secondsToFirstAction: Int?)

    var name: String {
        switch self {
        case .searchOpened: return "search_opened"
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
        case .activated: return "activated"
        case .sessionOutcome: return "session_outcome"
        }
    }

    var properties: [String: Any] {
        switch self {
        case let .searchOpened(gridFilled, isReplacement):
            return ["grid_filled": gridFilled, "is_replacement": isReplacement]
        case let .searchSettled(results, backfills, hintArrived, cacheHits, throttled,
                                queryLength, wordCount, isRefinement):
            return ["results": results,
                    "backfills": backfills,
                    "hint_arrived": hintArrived,
                    "cache_hits": cacheHits,
                    "throttled": throttled,
                    "query_length": queryLength,
                    "word_count": wordCount,
                    "is_refinement": isRefinement]
        case let .albumPlaced(position, backfilled, source):
            return ["position": position,
                    "backfilled": backfilled,
                    "source": source.rawValue]
        case let .searchAbandoned(searches, failedSearches, typed):
            return ["searches": searches,
                    "failed_searches": failedSearches,
                    "typed": typed]
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
        case let .activated(milestone, secondsSinceInstall, sessionNumber):
            return ["milestone": milestone.rawValue,
                    "seconds_since_install": secondsSinceInstall,
                    "session_number": sessionNumber]
        case let .sessionOutcome(albumsPlaced, gridFilled, searchesOpened,
                                 saved, exported, seconds, secondsToFirstAction):
            var props: [String: Any] = ["albums_placed": albumsPlaced,
                                        "grid_filled": gridFilled,
                                        "searches_opened": searchesOpened,
                                        "saved": saved,
                                        "exported": exported,
                                        "seconds": seconds]
            // Omitted rather than sent as a sentinel, so "did nothing at all"
            // is a missing property instead of a number that charts as zero.
            if let secondsToFirstAction {
                props["seconds_to_first_action"] = secondsToFirstAction
            }
            return props
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

    private static let counters = UsageCounters.shared

    /// Guards the session accumulator and the milestone claim. Every caller is
    /// on the main actor today except the cover fetcher, which reaches `track`
    /// from a background task.
    private static let lock = NSLock()
    private static var session = SessionMetrics()
    private static var sessionIsOpen = false

    /// Call once at launch.
    static func start() {
        let sessionNumber = counters.recordLaunch()

        // appLifecycles adds Application Installed, Opened and Updated for
        // free, which is what anchors an activation funnel to installs rather
        // than to whoever happened to send an event. Sessions are the SDK
        // default; screen views and element interactions stay off, since this
        // taxonomy is deliberate and autocaptured taps would bury it.
        let configuration = Configuration(apiKey: apiKey,
                                          autocapture: [.sessions, .appLifecycles])
        let amplitude = Amplitude(configuration: configuration)

        // Debug and simulator sessions reach the same dashboard but carry a
        // build property, so development noise is one filter away from gone.
        let identify = Identify()
        #if DEBUG
        identify.set(property: "build", value: "debug")
        #else
        identify.set(property: "build", value: "release")
        #endif

        // Lifetime state as user properties, so every event is segmentable by
        // how experienced the person sending it is. A 40 second first session
        // and a 40 second fiftieth session are opposite findings.
        identify.set(property: "session_count", value: sessionNumber)
        identify.set(property: "days_since_install", value: counters.daysSinceInstall)
        identify.set(property: "lifetime_albums_placed", value: counters.albumsPlaced)
        identify.set(property: "lifetime_grids_saved", value: counters.gridsSaved)
        identify.set(property: "lifetime_exports", value: counters.exports)

        amplitude.identify(identify: identify)

        Self.amplitude = amplitude
        beginSession()
    }

    static func track(_ event: AnalyticsEvent) {
        lock.lock()
        session.observe(event)
        lock.unlock()

        log.notice("\(event.name, privacy: .public)")
        amplitude?.track(eventType: event.name, eventProperties: event.properties)

        recordLifetime(event)
    }

    /// Lifetime counters and milestones ride the events rather than the call
    /// sites. A new way to place an album or write an export cannot forget to
    /// count itself, because counting happens where the event does.
    private static func recordLifetime(_ event: AnalyticsEvent) {
        switch event {
        case .albumPlaced:
            counters.recordAlbumPlaced()
            claim(.firstAlbumPlaced)
        case .gridSaved:
            counters.recordGridSaved()
            claim(.firstGridSaved)
        case .exportSaved:
            counters.recordExport()
            claim(.firstExportSaved)
        default:
            break
        }
    }

    /// Sends the milestone event the first time this install reaches it, and
    /// never again. Reached only from recordLifetime, which ignores
    /// `.activated`, so this cannot recurse.
    private static func claim(_ milestone: ActivationMilestone) {
        lock.lock()
        let isFirst = counters.claim(milestone)
        lock.unlock()

        guard isFirst else { return }

        track(.activated(milestone: milestone,
                         secondsSinceInstall: counters.secondsSinceInstall,
                         sessionNumber: counters.sessionCount))
    }

    /// Starts a fresh accumulator. Called at launch and on every return from
    /// the background, and safe to call twice.
    static func beginSession() {
        lock.lock()
        defer { lock.unlock() }

        guard !sessionIsOpen else { return }
        session.begin()
        sessionIsOpen = true
    }

    /// Closes the session and sends its shape.
    ///
    /// `gridFilled` comes from the caller because it is state, not an event
    /// total: a grid can arrive at this session already full from the last one.
    static func endSession(gridFilled: Int) {
        lock.lock()
        guard sessionIsOpen else {
            lock.unlock()
            return
        }
        let finished = session
        sessionIsOpen = false
        lock.unlock()

        track(.sessionOutcome(albumsPlaced: finished.albumsPlaced,
                              gridFilled: gridFilled,
                              searchesOpened: finished.searchesOpened,
                              saved: finished.saved,
                              exported: finished.exported,
                              seconds: finished.seconds,
                              secondsToFirstAction: finished.secondsToFirstAction))

        amplitude?.flush()
    }
}
