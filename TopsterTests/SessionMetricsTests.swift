//
//  SessionMetricsTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// session_outcome is the only event a bounced session sends, so what it
/// counts has to be exactly right. These pin down what does and does not
/// register as something a person did.
final class SessionMetricsTests: XCTestCase {

    private func settled() -> AnalyticsEvent {
        .searchSettled(results: 20, backfills: 0, hintArrived: true, cacheHits: 0,
                       throttled: false, queryLength: 5, wordCount: 1, isRefinement: false)
    }

    func testAFreshSessionCountsNothing() {
        let session = SessionMetrics()

        XCTAssertEqual(session.albumsPlaced, 0)
        XCTAssertEqual(session.searchesOpened, 0)
        XCTAssertFalse(session.saved)
        XCTAssertFalse(session.exported)
        XCTAssertNil(session.secondsToFirstAction)
    }

    func testItAccumulatesAWorkingSession() {
        var session = SessionMetrics()

        session.observe(.searchOpened(gridFilled: 0, isReplacement: false))
        session.observe(settled())
        session.observe(.albumPlaced(position: 1, backfilled: false, source: .search))
        session.observe(.searchOpened(gridFilled: 1, isReplacement: false))
        session.observe(.albumPlaced(position: 4, backfilled: true, source: .search))
        session.observe(.gridSaved(layout: "fortyTwo", savedGrids: 1))
        session.observe(.exportSaved(layout: "fortyTwo"))

        XCTAssertEqual(session.albumsPlaced, 2)
        XCTAssertEqual(session.searchesOpened, 2)
        XCTAssertTrue(session.saved)
        XCTAssertTrue(session.exported)
        XCTAssertNotNil(session.secondsToFirstAction)
    }

    /// The bounce. Opening the sheet and closing it is an action, and it is
    /// the action this whole event exists to make visible.
    func testOpeningTheSheetCountsAsAnAction() {
        var session = SessionMetrics()
        session.observe(.searchOpened(gridFilled: 0, isReplacement: false))

        XCTAssertEqual(session.searchesOpened, 1)
        XCTAssertEqual(session.albumsPlaced, 0)
        XCTAssertNotNil(session.secondsToFirstAction)
    }

    /// A cover failing is server weather, not something the person did. If it
    /// stopped the first-action clock, every session on a bad CDN day would
    /// report an instant first action nobody performed.
    func testCoverFailuresAreNotUserActions() {
        var session = SessionMetrics()

        session.observe(.coverFetchFailed(confirmedDead: true))
        session.observe(.coverFetchFailed(confirmedDead: false))

        XCTAssertNil(session.secondsToFirstAction)
        XCTAssertEqual(session.albumsPlaced, 0)
    }

    /// The outcome event and the milestone event are output, not input.
    /// Observing them would make a session look active because it ended.
    func testItsOwnOutputIsNotAnAction() {
        var session = SessionMetrics()

        session.observe(.activated(milestone: .firstAlbumPlaced,
                                   secondsSinceInstall: 10, sessionNumber: 1))
        session.observe(.sessionOutcome(albumsPlaced: 0, gridFilled: 0, searchesOpened: 0,
                                        saved: false, exported: false,
                                        seconds: 3, secondsToFirstAction: nil))

        XCTAssertNil(session.secondsToFirstAction)
    }

    /// Abandoning is an action too. It is a person trying and failing, which
    /// is not the same as a person doing nothing.
    func testAbandonmentRegistersAsAnAction() {
        var session = SessionMetrics()
        session.observe(.searchAbandoned(searches: 0, failedSearches: 0, typed: false))

        XCTAssertNotNil(session.secondsToFirstAction)
    }

    func testBeginWipesThePreviousSession() {
        var session = SessionMetrics()
        session.observe(.albumPlaced(position: 1, backfilled: false, source: .search))
        session.observe(.exportSaved(layout: "twenty"))

        session.begin()

        XCTAssertEqual(session.albumsPlaced, 0)
        XCTAssertFalse(session.exported)
        XCTAssertNil(session.secondsToFirstAction)
    }
}
