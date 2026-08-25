//
//  CoverArchiveTests.swift
//  TopsterUITests
//

import XCTest

/// Saving a grid should leave a local copy of its cover art behind, so the grid
/// still renders after Last.fm drops a URL or the device goes offline.
final class CoverArchiveTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Stages a grid, saves it, and holds long enough for the archive write to land.
    ///
    /// The archive is written on a background queue from whatever is already in
    /// URLCache, so the covers have to be on screen before the save is tapped.
    func testSavingAGridArchivesItsCovers() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        app.launch()

        // Covers must finish loading, otherwise there is nothing cached to archive.
        Thread.sleep(forTimeInterval: 15)

        let save = app.buttons["Save grid"]
        XCTAssertTrue(save.waitForExistence(timeout: 20), "Save grid button never appeared")
        save.tap()

        Thread.sleep(forTimeInterval: 8)
        attach(named: "01-after-save")

        Thread.sleep(forTimeInterval: 12)
    }

    /// Renders whatever is already saved. Run after wiping URLCache to prove the
    /// covers are coming off disk rather than being refetched.
    func testRendersFromArchiveAlone() throws {
        let app = XCUIApplication()
        app.launch()

        // Short on purpose. A cold network fetch takes 0.3 to 7.6 seconds, so
        // anything rendered this fast came from local disk.
        Thread.sleep(forTimeInterval: 3)
        attach(named: "02-archive-only")

        Thread.sleep(forTimeInterval: 20)
    }

    private func attach(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
