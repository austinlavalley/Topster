//
//  SearchOrderDiagnostics.swift
//  TopsterUITests
//

import XCTest

/// Reads the actual order of search results out of the running app, so whether
/// the Deezer re-rank did anything is a printed list rather than a feeling.
/// Compare its output with the app's own search-ranking log line, which says
/// whether the hint arrived in time and how many albums it moved.
final class SearchOrderDiagnostics: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Queries come from TEST_RUNNER_SEARCH_QUERIES (comma-separated) so a batch
    /// can be driven from the Windows side without editing this file.
    func testSearchesReportTheirResultOrder() throws {
        let queries = (ProcessInfo.processInfo.environment["SEARCH_QUERIES"] ?? "blue")
            .split(separator: ",").map(String.init)

        let app = XCUIApplication()
        app.launch()

        Thread.sleep(forTimeInterval: 10)

        // Same route into the search sheet as CoverRefreshTests: tap the first cell.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.17)).tap()

        let field = app.textFields["album-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "search field never appeared")
        field.tap()

        for query in queries {
            field.typeText(query)

            // Debounce, both requests, backfill budget, covers starting to render.
            Thread.sleep(forTimeInterval: 12)

            let results = app.descendants(matching: .any).matching(identifier: "search-result")

            // Zero results is a state to report, not a failure: the no-results
            // message path is one of the behaviours this diagnostic checks.
            let order = results.count == 0
                ? "(no results; empty-state message shown instead)"
                : (0..<min(results.count, 10)).map { i in
                    "\(i + 1). \(results.element(boundBy: i).label)"
                }.joined(separator: "\n")

            // NSLog so the order also lands in the xcodebuild output, not only
            // the result bundle.
            NSLog("SEARCH ORDER for \"%@\":\n%@", query, order)

            let attachment = XCTAttachment(string: order)
            attachment.name = "result-order-\(query)"
            attachment.lifetime = .keepAlways
            add(attachment)

            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "results-\(query)"
            shot.lifetime = .keepAlways
            add(shot)

            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue,
                                  count: query.count))
            Thread.sleep(forTimeInterval: 1)
        }
    }
}
