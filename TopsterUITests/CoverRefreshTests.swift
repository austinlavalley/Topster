//
//  CoverRefreshTests.swift
//  TopsterUITests
//

import XCTest

/// Guards the reason the app had two image loaders for two years.
///
/// From the history: "added a separate albumsquare model that uses asyncimage rather
/// than custom image fetching due to problems with custom downloader not refreshing
/// the main grid view" (Nov 2023). The loader kept its image in plain `@State`, and
/// SwiftUI reuses a view when only its properties change, so a slot could keep
/// showing the previous album's cover.
///
/// The original report was about the grid "updating/changing", which is broader than
/// swapping a single album. These cover the ways a grid changes underneath its cells.
final class CoverRefreshTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ app: XCUIApplication, savedGrids: Bool = false) {
        var args: [String] = []

        if savedGrids, let seed = ProcessInfo.processInfo.environment["SAVED_HEX"], !seed.isEmpty {
            args += ["-storedSavedGrids", "<\(seed)>"]
        }
        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            args += ["-FortyGridDict", "<\(seed)>"]
        }

        app.launchArguments = args
        app.launch()
    }

    // MARK: - One slot at a time

    /// Replacing an album has to change that cell's cover. The 2023 bug in its
    /// simplest form. Crops are compared outside the test: identical pixels in that
    /// cell mean the stale image is back.
    func testReplacingAnAlbumChangesItsCover() throws {
        let app = XCUIApplication()
        launch(app)

        Thread.sleep(forTimeInterval: 22)
        attach(named: "01-before-replace")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.17)).tap()
        Thread.sleep(forTimeInterval: 4)

        let field = app.textFields["album-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "search field never appeared")
        field.tap()
        field.typeText("nevermind nirvana")
        Thread.sleep(forTimeInterval: 14)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.42)).tap()
        Thread.sleep(forTimeInterval: 12)
        attach(named: "03-after-replace")

        Thread.sleep(forTimeInterval: 4)
    }

    /// The same swap in a cell further down. Slot one is the easy case and was the
    /// only one previously covered.
    func testReplacingAnAlbumInALaterSlotChangesItsCover() throws {
        let app = XCUIApplication()
        launch(app)

        Thread.sleep(forTimeInterval: 22)
        attach(named: "10-before-later-slot")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.45)).tap()
        Thread.sleep(forTimeInterval: 4)

        let field = app.textFields["album-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "search field never appeared")
        field.tap()
        field.typeText("purple rain prince")
        Thread.sleep(forTimeInterval: 14)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.42)).tap()
        Thread.sleep(forTimeInterval: 12)
        attach(named: "11-after-later-slot")

        Thread.sleep(forTimeInterval: 4)
    }

    // MARK: - The whole grid at once

    /// The case closest to the original 2023 report: the grid changing underneath its
    /// cells wholesale. Two saved grids sharing no albums are opened in turn. Any
    /// cover surviving the switch shows up in the comparison outside the test.
    func testOpeningADifferentSavedGridReplacesEveryCover() throws {
        let app = XCUIApplication()
        launch(app, savedGrids: true)

        Thread.sleep(forTimeInterval: 12)

        let saved = app.buttons["Saved"]
        XCTAssertTrue(saved.waitForExistence(timeout: 12), "Saved tab never appeared")
        saved.tap()
        Thread.sleep(forTimeInterval: 8)
        attach(named: "20-saved-list")

        // Card centres read off a screenshot of the list. Guessing put the second
        // tap in empty space below the card, which silently re-opened the first.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28)).tap()
        Thread.sleep(forTimeInterval: 3)

        let grid = app.buttons["Grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 10), "Grid tab never appeared")
        grid.tap()
        Thread.sleep(forTimeInterval: 20)
        attach(named: "21-first-saved-grid")

        saved.tap()
        Thread.sleep(forTimeInterval: 5)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.47)).tap()
        Thread.sleep(forTimeInterval: 3)

        grid.tap()
        Thread.sleep(forTimeInterval: 20)
        attach(named: "22-second-saved-grid")

        Thread.sleep(forTimeInterval: 4)
    }

    // MARK: - Recycling

    /// Scrolls the grid hard and checks nothing returns to a loading state.
    ///
    /// `.task(id:)` cancels when a cell scrolls out of view and restarts when it
    /// comes back, so this is the risk in moving off `onAppear`: covers re-requesting
    /// on every scroll. `CoverMemoryCache` is what should make the restart free.
    func testScrollingDoesNotReloadCovers() throws {
        let app = XCUIApplication()
        launch(app)

        Thread.sleep(forTimeInterval: 22)
        attach(named: "05-scroll-settled")

        // Swipe the real scroll views. A fast synthetic coordinate drag does not
        // register as a scroll, and a test that never scrolls passes for free.
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

        Thread.sleep(forTimeInterval: 4)
    }

    private func attach(named name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
