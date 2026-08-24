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

    private func openExport(_ app: XCUIApplication) {
        let export = app.buttons["Export"]
        XCTAssertTrue(export.waitForExistence(timeout: 20), "Export button never appeared")
        export.tap()
    }

    private func closeExport(_ app: XCUIApplication) {
        // The sheet's dismiss control is the only xmark image button on screen.
        let close = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'xmark'")).firstMatch
        if close.exists {
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
