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

    func testEventNamesAreStable() {
        XCTAssertEqual(AnalyticsEvent.searchSettled(results: 0, backfills: 0, hintArrived: true,
                                                    cacheHits: 0, throttled: false).name,
                       "search_settled")
        XCTAssertEqual(AnalyticsEvent.albumPlaced(position: 1, backfilled: false).name,
                       "album_placed")
        XCTAssertEqual(AnalyticsEvent.searchAbandoned(searches: 2).name, "search_abandoned")
        XCTAssertEqual(AnalyticsEvent.albumRemoved.name, "album_removed")
        XCTAssertEqual(AnalyticsEvent.gridSaved(layout: "fortyTwo").name, "grid_saved")
        XCTAssertEqual(AnalyticsEvent.layoutSelected(layout: "twenty").name, "layout_selected")
        XCTAssertEqual(AnalyticsEvent.exportPreviewed(layout: "fortyTwo").name, "export_previewed")
        XCTAssertEqual(AnalyticsEvent.exportSaved(layout: "fortyTwo").name, "export_saved")
        XCTAssertEqual(AnalyticsEvent.coverFetchFailed(confirmedDead: true).name,
                       "cover_fetch_failed")
    }

    /// The abandonment counterpart to albumPlaced, and the cover-weather flag.
    func testNewEventsCarryTheirShapes() {
        XCTAssertEqual(AnalyticsEvent.searchAbandoned(searches: 3).properties["searches"] as? Int, 3)
        XCTAssertTrue(AnalyticsEvent.albumRemoved.properties.isEmpty)
        XCTAssertEqual(AnalyticsEvent.exportPreviewed(layout: "twenty").properties["layout"] as? String,
                       "twenty")
        XCTAssertEqual(AnalyticsEvent.coverFetchFailed(confirmedDead: false)
                        .properties["confirmed_dead"] as? Bool, false)
    }

    func testSearchSettledCarriesItsCounts() {
        let props = AnalyticsEvent.searchSettled(results: 40, backfills: 3, hintArrived: true,
                                                 cacheHits: 12, throttled: false).properties

        XCTAssertEqual(props["results"] as? Int, 40)
        XCTAssertEqual(props["backfills"] as? Int, 3)
        XCTAssertEqual(props["hint_arrived"] as? Bool, true)
        XCTAssertEqual(props["cache_hits"] as? Int, 12)
        XCTAssertEqual(props["throttled"] as? Bool, false)
    }

    /// The metric that grades the ranking work: position and provenance.
    func testAlbumPlacedCarriesPositionAndProvenance() {
        let props = AnalyticsEvent.albumPlaced(position: 2, backfilled: true).properties

        XCTAssertEqual(props["position"] as? Int, 2)
        XCTAssertEqual(props["backfilled"] as? Bool, true)
    }

    func testLayoutEventsCarryTheLayout() {
        XCTAssertEqual(AnalyticsEvent.gridSaved(layout: "twentyFive").properties["layout"] as? String,
                       "twentyFive")
        XCTAssertEqual(AnalyticsEvent.layoutSelected(layout: "twenty").properties["layout"] as? String,
                       "twenty")
        XCTAssertEqual(AnalyticsEvent.exportSaved(layout: "fortyTwo").properties["layout"] as? String,
                       "fortyTwo")
    }

    /// The privacy promise, enforced: no event property may carry free text a
    /// user typed. Everything is a count, a flag, or a layout name from a
    /// fixed enum.
    func testNoEventCarriesFreeText() {
        let events: [AnalyticsEvent] = [
            .searchSettled(results: 1, backfills: 1, hintArrived: true, cacheHits: 1, throttled: true),
            .albumPlaced(position: 1, backfilled: true),
            .searchAbandoned(searches: 2),
            .albumRemoved,
            .gridSaved(layout: "fortyTwo"),
            .layoutSelected(layout: "fortyTwo"),
            .exportPreviewed(layout: "fortyTwo"),
            .exportSaved(layout: "fortyTwo"),
            .coverFetchFailed(confirmedDead: true),
        ]
        let allowedStrings = Set(["fortyTwo", "twenty", "twentyWide", "twentyFive"])

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
