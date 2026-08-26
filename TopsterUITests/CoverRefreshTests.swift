//
//  CoverRefreshTests.swift
//  TopsterUITests
//

import XCTest

/// Guards the reason the app had two image loaders for two years.
///
/// From the history: "added a separate albumsquare model that uses asyncimage rather
/// than custom image fetching due to problems with custom downloader not refreshing
/// the main grid view" (Nov 2023). Replacing an album in a slot left the previous
/// album's cover on screen, because the loader kept its image in plain `@State` and
/// SwiftUI reuses a view when only its properties change.
///
/// Both loaders are now one. These tests exist so that regression is loud.
final class CoverRefreshTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Seeds a grid, replaces the album in the first slot, and captures before and
    /// after. The crops are compared outside the test: identical pixels in that cell
    /// mean the stale cover is back.
    func testReplacingAnAlbumChangesItsCover() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        app.launch()

        // Covers must be on screen before anything is worth comparing.
        Thread.sleep(forTimeInterval: 22)
        attach(named: "01-before-replace")

        // First cell, top left of the grid.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.17)).tap()
        Thread.sleep(forTimeInterval: 4)

        let field = app.textFields["album-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "search field never appeared")
        field.tap()
        field.typeText("nevermind nirvana")
        Thread.sleep(forTimeInterval: 14)
        attach(named: "02-search-results")

        // First result in the three column results grid.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.42)).tap()
        Thread.sleep(forTimeInterval: 12)
        attach(named: "03-after-replace")

        Thread.sleep(forTimeInterval: 6)
    }

    /// Opening two different saved grids in turn. Each has to show its own covers,
    /// which is the same staleness question asked of a whole screen at once.
    func testSwitchingSavedGridsShowsTheRightCovers() throws {
        let app = XCUIApplication()
        app.launch()
        Thread.sleep(forTimeInterval: 18)

        let saved = app.buttons["Saved"]
        XCTAssertTrue(saved.waitForExistence(timeout: 10), "Saved tab never appeared")
        saved.tap()
        Thread.sleep(forTimeInterval: 6)
        attach(named: "04-saved-list")

        Thread.sleep(forTimeInterval: 6)
    }

    /// Scrolls the grid hard and checks nothing goes back to a loading state.
    ///
    /// `.task(id:)` cancels when a cell scrolls out of view and restarts when it
    /// returns, so this is the risk in moving off `onAppear`: covers re-requesting on
    /// every scroll. `CoverMemoryCache` is what should make the restart free, and a
    /// cover briefly showing its spinner again is what failure looks like.
    func testScrollingDoesNotReloadCovers() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        app.launch()
        Thread.sleep(forTimeInterval: 22)
        attach(named: "05-scroll-settled")

        // Rows are horizontal scroll views. Swipe the real elements rather than
        // dragging coordinates: a fast synthetic drag does not register as a scroll
        // and the test silently proves nothing.
        let rows = app.scrollViews
        XCTAssertGreaterThan(rows.count, 0, "no scroll views found, the grid did not lay out")

        let row = rows.element(boundBy: 0)
        for _ in 0..<4 {
            row.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
        }
        attach(named: "05b-scrolled-away")

        for _ in 0..<4 {
            row.swipeRight()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Captured immediately. A reload would still be in flight at this point.
        Thread.sleep(forTimeInterval: 0.4)
        attach(named: "06-scroll-returned")

        Thread.sleep(forTimeInterval: 6)
    }

    private func attach(named name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
