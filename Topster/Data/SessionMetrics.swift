//
//  SessionMetrics.swift
//  Topster
//

import Foundation

/// What one foreground session amounted to, accumulated from the events that
/// already flow through `Analytics.track`.
///
/// This exists because the bounce case emits nothing. Someone who opens the
/// app, taps a square, closes the search sheet and quits produced no event at
/// all before this, so the shortest sessions were not short rows in the
/// dashboard, they were absent ones. One event at background makes every
/// session comparable, including the empty ones.
///
/// Fed by observing events rather than by call sites, so a new placement path
/// cannot forget to report itself.
struct SessionMetrics {

    private(set) var startedAt = Date()
    private(set) var firstActionAt: Date?
    private(set) var albumsPlaced = 0
    private(set) var searchesOpened = 0
    private(set) var saved = false
    private(set) var exported = false

    var seconds: Int { max(0, Int(Date().timeIntervalSince(startedAt))) }

    var secondsToFirstAction: Int? {
        firstActionAt.map { at in max(0, Int(at.timeIntervalSince(startedAt))) }
    }

    mutating func begin() {
        self = SessionMetrics()
    }

    /// Only deliberate acts count. A cover fetch failing is server weather,
    /// not something the person did, so it must not stop the clock on
    /// `seconds_to_first_action`.
    mutating func observe(_ event: AnalyticsEvent) {
        switch event {
        case .searchOpened:
            searchesOpened += 1
        case .albumPlaced:
            albumsPlaced += 1
        case .gridSaved:
            saved = true
        case .exportSaved:
            exported = true
        case .searchSettled, .searchAbandoned, .albumRemoved, .layoutSelected,
             .exportPreviewed, .exportSaveAttempted:
            break
        case .coverFetchFailed, .activated, .sessionOutcome:
            return
        }

        if firstActionAt == nil { firstActionAt = Date() }
    }
}
