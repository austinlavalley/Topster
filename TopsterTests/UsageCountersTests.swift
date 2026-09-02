//
//  UsageCountersTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// These back two things that cannot be re-derived after the fact: a milestone
/// that fires twice inflates activation forever, and a session count that
/// resets makes every user look new.
final class UsageCountersTests: XCTestCase {

    private var defaults: UserDefaults!
    private var counters: UsageCounters!
    private let suite = "UsageCountersTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        counters = UsageCounters(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func testSessionCountStartsAtOneAndClimbs() {
        XCTAssertEqual(counters.sessionCount, 0)
        XCTAssertEqual(counters.recordLaunch(), 1)
        XCTAssertEqual(counters.recordLaunch(), 2)
        XCTAssertEqual(counters.recordLaunch(), 3)
        XCTAssertEqual(counters.sessionCount, 3)
    }

    /// The install date is stamped once and then left alone, or every launch
    /// resets days_since_install to zero.
    func testInstallDateIsStampedOnceAndSurvivesLaterLaunches() {
        counters.recordLaunch()
        let first = counters.installDate

        counters.recordLaunch()
        counters.recordLaunch()

        XCTAssertEqual(counters.installDate.timeIntervalSince1970,
                       first.timeIntervalSince1970,
                       accuracy: 0.001)
        XCTAssertEqual(counters.daysSinceInstall, 0)
    }

    func testLifetimeCountersAccumulate() {
        XCTAssertEqual(counters.albumsPlaced, 0)
        XCTAssertEqual(counters.gridsSaved, 0)
        XCTAssertEqual(counters.exports, 0)

        counters.recordAlbumPlaced()
        counters.recordAlbumPlaced()
        counters.recordGridSaved()
        counters.recordExport()

        XCTAssertEqual(counters.albumsPlaced, 2)
        XCTAssertEqual(counters.gridsSaved, 1)
        XCTAssertEqual(counters.exports, 1)
    }

    /// The whole point of the type. Claim once, never again.
    func testMilestoneIsClaimedExactlyOnce() {
        XCTAssertFalse(counters.hasPassed(.firstAlbumPlaced))

        XCTAssertTrue(counters.claim(.firstAlbumPlaced))
        XCTAssertTrue(counters.hasPassed(.firstAlbumPlaced))

        XCTAssertFalse(counters.claim(.firstAlbumPlaced))
        XCTAssertFalse(counters.claim(.firstAlbumPlaced))
    }

    func testMilestonesAreIndependent() {
        XCTAssertTrue(counters.claim(.firstAlbumPlaced))

        XCTAssertFalse(counters.hasPassed(.firstGridSaved))
        XCTAssertFalse(counters.hasPassed(.firstExportSaved))
        XCTAssertTrue(counters.claim(.firstGridSaved))
        XCTAssertTrue(counters.claim(.firstExportSaved))
    }

    /// A claimed milestone is persisted, not held in memory, so reinstalling
    /// the type over the same store does not re-arm it.
    func testClaimSurvivesANewInstanceOverTheSameStore() {
        XCTAssertTrue(counters.claim(.firstExportSaved))

        let reopened = UsageCounters(defaults: defaults)
        XCTAssertTrue(reopened.hasPassed(.firstExportSaved))
        XCTAssertFalse(reopened.claim(.firstExportSaved))
    }

    func testResetClearsEverythingItOwns() {
        counters.recordLaunch()
        counters.recordAlbumPlaced()
        _ = counters.claim(.firstAlbumPlaced)

        counters.reset()

        XCTAssertEqual(counters.sessionCount, 0)
        XCTAssertEqual(counters.albumsPlaced, 0)
        XCTAssertFalse(counters.hasPassed(.firstAlbumPlaced))
    }
}
