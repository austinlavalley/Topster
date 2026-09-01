//
//  AnalyticsEventTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// The event taxonomy is the contract with the Amplitude dashboard: renaming
/// an event or a property silently orphans every chart built on it. These pin
/// the names and shapes down.
final class AnalyticsEventTests: XCTestCase {

    private func settled(results: Int = 0, backfills: Int = 0, hintArrived: Bool = true,
                         cacheHits: Int = 0, throttled: Bool = false,
                         queryLength: Int = 4, wordCount: Int = 1,
                         isRefinement: Bool = false) -> AnalyticsEvent {
        .searchSettled(results: results, backfills: backfills, hintArrived: hintArrived,
                       cacheHits: cacheHits, throttled: throttled,
                       queryLength: queryLength, wordCount: wordCount,
                       isRefinement: isRefinement)
    }

    func testEventNamesAreStable() {
        XCTAssertEqual(AnalyticsEvent.searchOpened(gridFilled: 0, isReplacement: false).name,
                       "search_opened")
        XCTAssertEqual(settled().name, "search_settled")
        XCTAssertEqual(AnalyticsEvent.albumPlaced(position: 1, backfilled: false, source: .search).name,
                       "album_placed")
        XCTAssertEqual(AnalyticsEvent.searchAbandoned(searches: 2, failedSearches: 0, typed: true).name,
                       "search_abandoned")
        XCTAssertEqual(AnalyticsEvent.albumRemoved.name, "album_removed")
        XCTAssertEqual(AnalyticsEvent.gridSaved(layout: "fortyTwo", savedGrids: 3).name,
                       "grid_saved")
        XCTAssertEqual(AnalyticsEvent.layoutSelected(layout: "twenty").name, "layout_selected")
        XCTAssertEqual(AnalyticsEvent.exportPreviewed(layout: "fortyTwo", filled: 12).name,
                       "export_previewed")
        XCTAssertEqual(AnalyticsEvent.exportSaveAttempted(layout: "fortyTwo").name,
                       "export_save_attempted")
        XCTAssertEqual(AnalyticsEvent.exportSaved(layout: "fortyTwo").name, "export_saved")
        XCTAssertEqual(AnalyticsEvent.coverFetchFailed(confirmedDead: true).name,
                       "cover_fetch_failed")
        XCTAssertEqual(AnalyticsEvent.activated(milestone: .firstAlbumPlaced,
                                                secondsSinceInstall: 30, sessionNumber: 1).name,
                       "activated")
        XCTAssertEqual(AnalyticsEvent.sessionOutcome(albumsPlaced: 0, gridFilled: 0, searchesOpened: 0,
                                                     saved: false, exported: false,
                                                     seconds: 12, secondsToFirstAction: nil).name,
                       "session_outcome")
    }

    /// The abandonment counterpart to albumPlaced, and the cover-weather flag.
    func testNewEventsCarryTheirShapes() {
        let abandoned = AnalyticsEvent.searchAbandoned(searches: 3, failedSearches: 1, typed: true)
        XCTAssertEqual(abandoned.properties["searches"] as? Int, 3)
        XCTAssertEqual(abandoned.properties["failed_searches"] as? Int, 1)
        XCTAssertEqual(abandoned.properties["typed"] as? Bool, true)

        XCTAssertTrue(AnalyticsEvent.albumRemoved.properties.isEmpty)
        XCTAssertEqual(AnalyticsEvent.exportPreviewed(layout: "twenty", filled: 7)
                        .properties["layout"] as? String, "twenty")
        XCTAssertEqual(AnalyticsEvent.exportPreviewed(layout: "twenty", filled: 7)
                        .properties["filled"] as? Int, 7)
        XCTAssertEqual(AnalyticsEvent.gridSaved(layout: "twenty", savedGrids: 5)
                        .properties["saved_grids"] as? Int, 5)
        XCTAssertEqual(AnalyticsEvent.coverFetchFailed(confirmedDead: false)
                        .properties["confirmed_dead"] as? Bool, false)
    }

    /// Opening the search sheet used to emit nothing, which is what made a
    /// bounced first session invisible.
    func testSearchOpenedSeparatesFillingFromSwapping() {
        let fresh = AnalyticsEvent.searchOpened(gridFilled: 0, isReplacement: false).properties
        XCTAssertEqual(fresh["grid_filled"] as? Int, 0)
        XCTAssertEqual(fresh["is_replacement"] as? Bool, false)

        let swap = AnalyticsEvent.searchOpened(gridFilled: 18, isReplacement: true).properties
        XCTAssertEqual(swap["grid_filled"] as? Int, 18)
        XCTAssertEqual(swap["is_replacement"] as? Bool, true)
    }

    func testSearchSettledCarriesItsCounts() {
        let props = settled(results: 40, backfills: 3, hintArrived: true,
                            cacheHits: 12, throttled: false).properties

        XCTAssertEqual(props["results"] as? Int, 40)
        XCTAssertEqual(props["backfills"] as? Int, 3)
        XCTAssertEqual(props["hint_arrived"] as? Bool, true)
        XCTAssertEqual(props["cache_hits"] as? Int, 12)
        XCTAssertEqual(props["throttled"] as? Bool, false)
    }

    /// Query shape, which is what tells a buried album from a missing one.
    func testSearchSettledCarriesQueryShapeAndNotTheQuery() {
        let props = settled(queryLength: 13, wordCount: 2, isRefinement: true).properties

        XCTAssertEqual(props["query_length"] as? Int, 13)
        XCTAssertEqual(props["word_count"] as? Int, 2)
        XCTAssertEqual(props["is_refinement"] as? Bool, true)
        XCTAssertNil(props["query"])
    }

    /// The metric that grades the ranking work: position, provenance, surface.
    func testAlbumPlacedCarriesPositionProvenanceAndSource() {
        let props = AnalyticsEvent.albumPlaced(position: 2, backfilled: true, source: .search).properties

        XCTAssertEqual(props["position"] as? Int, 2)
        XCTAssertEqual(props["backfilled"] as? Bool, true)
        XCTAssertEqual(props["source"] as? String, "search")

        XCTAssertEqual(AnalyticsEvent.albumPlaced(position: 1, backfilled: false, source: .onboarding)
                        .properties["source"] as? String, "onboarding")
    }

    func testActivationCarriesWhatItCost() {
        let props = AnalyticsEvent.activated(milestone: .firstExportSaved,
                                             secondsSinceInstall: 420,
                                             sessionNumber: 3).properties

        XCTAssertEqual(props["milestone"] as? String, "first_export_saved")
        XCTAssertEqual(props["seconds_since_install"] as? Int, 420)
        XCTAssertEqual(props["session_number"] as? Int, 3)
    }

    func testSessionOutcomeCarriesTheWholeSession() {
        let props = AnalyticsEvent.sessionOutcome(albumsPlaced: 6, gridFilled: 14, searchesOpened: 8,
                                                  saved: true, exported: true,
                                                  seconds: 1_580,
                                                  secondsToFirstAction: 4).properties

        XCTAssertEqual(props["albums_placed"] as? Int, 6)
        XCTAssertEqual(props["grid_filled"] as? Int, 14)
        XCTAssertEqual(props["searches_opened"] as? Int, 8)
        XCTAssertEqual(props["saved"] as? Bool, true)
        XCTAssertEqual(props["exported"] as? Bool, true)
        XCTAssertEqual(props["seconds"] as? Int, 1_580)
        XCTAssertEqual(props["seconds_to_first_action"] as? Int, 4)
    }

    /// A session where nobody did anything omits the key rather than sending
    /// a zero, which would otherwise average in as an instant first action.
    func testSessionOutcomeOmitsFirstActionWhenThereWasNone() {
        let props = AnalyticsEvent.sessionOutcome(albumsPlaced: 0, gridFilled: 0, searchesOpened: 0,
                                                  saved: false, exported: false,
                                                  seconds: 9,
                                                  secondsToFirstAction: nil).properties

        XCTAssertNil(props["seconds_to_first_action"])
        XCTAssertEqual(props["seconds"] as? Int, 9)
    }

    func testLayoutEventsCarryTheLayout() {
        XCTAssertEqual(AnalyticsEvent.gridSaved(layout: "twentyFive", savedGrids: 1)
                        .properties["layout"] as? String, "twentyFive")
        XCTAssertEqual(AnalyticsEvent.layoutSelected(layout: "twenty").properties["layout"] as? String,
                       "twenty")
        XCTAssertEqual(AnalyticsEvent.exportSaved(layout: "fortyTwo").properties["layout"] as? String,
                       "fortyTwo")
    }

    /// The privacy promise, enforced: no event property may carry free text a
    /// user typed. Everything is a count, a flag, or a string from a fixed
    /// enum. Query shape is welcome here; query content is not.
    func testNoEventCarriesFreeText() {
        let events: [AnalyticsEvent] = [
            .searchOpened(gridFilled: 3, isReplacement: true),
            settled(results: 1, backfills: 1, hintArrived: true, cacheHits: 1, throttled: true,
                    queryLength: 9, wordCount: 2, isRefinement: true),
            .albumPlaced(position: 1, backfilled: true, source: .search),
            .albumPlaced(position: 1, backfilled: false, source: .onboarding),
            .albumPlaced(position: 1, backfilled: false, source: .suggestion),
            .searchAbandoned(searches: 2, failedSearches: 2, typed: true),
            .albumRemoved,
            .gridSaved(layout: "fortyTwo", savedGrids: 4),
            .layoutSelected(layout: "fortyTwo"),
            .exportPreviewed(layout: "fortyTwo", filled: 42),
            .exportSaveAttempted(layout: "fortyTwo"),
            .exportSaved(layout: "fortyTwo"),
            .coverFetchFailed(confirmedDead: true),
            .sessionOutcome(albumsPlaced: 1, gridFilled: 1, searchesOpened: 1,
                            saved: true, exported: true, seconds: 1, secondsToFirstAction: 1),
        ] + ActivationMilestone.allCases.map { milestone in
            AnalyticsEvent.activated(milestone: milestone, secondsSinceInstall: 1, sessionNumber: 1)
        }

        let layouts = Set(["fortyTwo", "twenty", "twentyWide", "twentyFive"])
        let sources = Set(["search", "onboarding", "suggestion"])
        let milestones = Set(ActivationMilestone.allCases.map { milestone in milestone.rawValue })
        let allowedStrings = layouts.union(sources).union(milestones)

        for event in events {
            for (key, value) in event.properties {
                if let text = value as? String {
                    XCTAssertTrue(allowedStrings.contains(text),
                                  "\(event.name).\(key) carries free text: \(text)")
                }
            }
        }
    }
}
