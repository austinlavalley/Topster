//
//  ExportRenderTests.swift
//  TopsterUITests
//

import XCTest

/// The export is a separate render target from the interactive grid, built offscreen
/// through `ImageRenderer`. Nothing outside the app can reach it without tapping
/// Export, which is why placeholder bugs in there went unnoticed.
final class ExportRenderTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Opens the export sheet twice.
    ///
    /// A dead cover URL is only discovered when something actually requests it. If the
    /// second open renders correctly and the first does not, the export is giving up
    /// before the 404 comes back rather than being wrong about what to draw.
    func testExportSheetRendersTwice() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        app.launch()
        Thread.sleep(forTimeInterval: 12)

        openExport(app)
        Thread.sleep(forTimeInterval: 6)
        attach(named: "01-export-first-open")
        Thread.sleep(forTimeInterval: 14)   // window for external capture

        closeExport(app)
        Thread.sleep(forTimeInterval: 3)

        openExport(app)
        Thread.sleep(forTimeInterval: 6)
        attach(named: "02-export-second-open")
        Thread.sleep(forTimeInterval: 14)   // window for external capture
    }

    /// Walks the titles option through its three states and captures each one.
    ///
    /// The captions and the sidebar are both drawn inside the offscreen render,
    /// so the only way to see either is the preview image on this sheet. The
    /// dark background is switched on for the list capture, because white text
    /// on black is where a colour mistake in the sidebar would show.
    func testExportTitleOptionsRender() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        // The titles choice persists across launches, and a run that stops
        // early leaves the simulator on whatever it last tapped. Pin the start
        // through the argument domain so the None assertion below is about
        // this launch, not the previous run.
        app.launchArguments += ["-exportLabels", "none"]

        // TEST_RUNNER_LAYOUT=twentyFive on the xcodebuild line opens the stored
        // grid on that layout without touching what the simulator has saved,
        // through the same argument-domain override the seed uses.
        if let layout = ProcessInfo.processInfo.environment["LAYOUT"], !layout.isEmpty {
            app.launchArguments += ["-activeGridType", layout]
        }

        app.launch()
        Thread.sleep(forTimeInterval: 12)

        openExport(app)
        Thread.sleep(forTimeInterval: 6)

        let titles = app.segmentedControls["export-titles"]
        XCTAssertTrue(titles.waitForExistence(timeout: 5), "titles control never appeared")
        XCTAssertTrue(titles.buttons["None"].isSelected, "titles should start at None")
        attach(named: "03-titles-none")

        titles.buttons["Overlay"].tap()
        Thread.sleep(forTimeInterval: 4)
        XCTAssertTrue(titles.buttons["Overlay"].isSelected)
        attach(named: "04-titles-overlay")

        app.segmentedControls["export-background"].buttons["Dark"].tap()
        titles.buttons["List"].tap()
        Thread.sleep(forTimeInterval: 4)
        XCTAssertTrue(titles.buttons["List"].isSelected)
        attach(named: "05-titles-list-dark")
        Thread.sleep(forTimeInterval: 14)   // window for external capture

        // Back to None so the persisted choice does not leak into the next run.
        titles.buttons["None"].tap()
        app.segmentedControls["export-background"].buttons["Light"].tap()
    }

    /// Found by identifier rather than label, so renaming the button does not break
    /// the test. It was called "Export" until the copy pass.
    private func openExport(_ app: XCUIApplication) {
        let preview = app.buttons["preview-grid"]
        XCTAssertTrue(preview.waitForExistence(timeout: 20), "preview button never appeared")
        preview.tap()
    }

    private func closeExport(_ app: XCUIApplication) {
        let close = app.buttons["export-close"]
        if close.waitForExistence(timeout: 5) {
            close.tap()
        } else {
            app.swipeDown(velocity: .fast)
        }
    }

    private func attach(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
