//
//  StoreScreenshots.swift
//  TopsterUITests
//

import XCTest

/// Captures App Store screenshots by driving the real app.
///
/// Not a correctness test. It asserts almost nothing and exists so the store assets
/// can be regenerated in a couple of minutes instead of by hand. Run it on a 6.9"
/// device, where the simulator's native output is exactly the 1260x2736 App Store
/// wants, and pull the attachments out of the result bundle.
///
///     xcodebuild test -only-testing:TopsterUITests/StoreScreenshots \
///       -destination "platform=iOS Simulator,name=iPhone Air" \
///       -resultBundlePath shots.xcresult
///     xcrun xcresulttool export attachments --path shots.xcresult --output-path out
///
/// Skip it in ordinary runs with -skip-testing:TopsterUITests/StoreScreenshots.
final class StoreScreenshots: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureStoreScreenshots() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        app.launch()

        // Everything has to be loaded before anything is worth photographing.
        Thread.sleep(forTimeInterval: 25)
        capture("01-grid")

        // Tap the first grid cell to open search. By coordinate, because the grid
        // cells have no identifiers yet.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.17)).tap()
        Thread.sleep(forTimeInterval: 3)

        let field = app.textFields["album-search-field"]
        if field.waitForExistence(timeout: 8) {
            field.tap()
            field.typeText("blue")
            Thread.sleep(forTimeInterval: 12)
            capture("02-search")
        }

        app.swipeDown(velocity: .fast)
        Thread.sleep(forTimeInterval: 3)

        let preview = app.buttons["preview-grid"]
        if preview.waitForExistence(timeout: 10) {
            preview.tap()
            Thread.sleep(forTimeInterval: 12)
            capture("03-preview")

            let close = app.buttons["export-close"]
            if close.waitForExistence(timeout: 5) { close.tap() }
            Thread.sleep(forTimeInterval: 3)
        }

        let saved = app.buttons["Saved"]
        if saved.waitForExistence(timeout: 8) {
            saved.tap()
            Thread.sleep(forTimeInterval: 6)
            capture("04-saved")
        }
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
