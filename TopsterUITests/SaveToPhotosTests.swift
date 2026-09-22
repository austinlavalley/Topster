//
//  SaveToPhotosTests.swift
//  TopsterUITests
//

import XCTest

/// The confirmation used to fire on the button tap rather than on the save, which
/// on a first save put "Grid saved to camera roll" underneath the permission prompt
/// before the user had agreed to anything. It is now the button's own state, so
/// the checks read the button's label. Reset Photos permission on the simulator
/// first (`simctl privacy <sim> reset photos com.austinlavalley.Topster`) or the
/// prompt half of this never happens.
final class SaveToPhotosTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testConfirmationWaitsForTheActualSave() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        // TEST_RUNNER_EXPORT_LOG_ENDPOINT points the export log at a capture
        // server, to check a real save sends it. Unset, debug builds send nothing.
        if let endpoint = ProcessInfo.processInfo.environment["EXPORT_LOG_ENDPOINT"], !endpoint.isEmpty {
            app.launchArguments += ["-ExportLogEndpoint", endpoint]
        }

        app.launch()
        Thread.sleep(forTimeInterval: 14)

        let preview = app.buttons["preview-grid"]
        XCTAssertTrue(preview.waitForExistence(timeout: 20), "preview button never appeared")
        preview.tap()
        Thread.sleep(forTimeInterval: 8)

        let save = app.buttons["save-to-photos"]
        XCTAssertTrue(save.waitForExistence(timeout: 15), "save button never appeared")
        XCTAssertEqual(save.label, "Save to Photos")

        // One loop watches for both the permission prompt and the confirmed
        // label from the moment of the tap. They cannot be waited for in turn:
        // the confirmed state lasts 1.5 seconds, and on a simulator that already
        // has permission the save is done inside a second, so three seconds
        // spent waiting for a prompt that never comes misses it. The earlier
        // version of this test slept 14 seconds and then attached a screenshot
        // without asserting anything, which is how it passed for weeks while
        // proving nothing.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var sawConfirmed = false
        var handledPrompt = false
        save.tap()

        let deadline = Date().addingTimeInterval(12)
        while Date() < deadline && !sawConfirmed {
            if !handledPrompt, springboard.alerts.firstMatch.exists {
                // First save on a fresh simulator: the prompt is up and the
                // button has not confirmed anything. Grant it, whatever the
                // button is called on this OS version.
                attach(named: "01-permission-prompt")
                XCTAssertFalse(save.label.contains("Saved"), "confirmed before the save happened")
                for label in ["Allow Access to All Photos", "Allow Full Access", "Allow", "OK"] {
                    let button = springboard.buttons[label]
                    if button.exists {
                        button.tap()
                        break
                    }
                }
                handledPrompt = true
            }
            if save.label.contains("Saved to Photos") {
                sawConfirmed = true
                attach(named: "02-confirmed-after-real-save")
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertTrue(sawConfirmed, "button never confirmed the save; label is \(save.label)")

        // And it returns to normal rather than sticking.
        let back = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Save to Photos"), object: save)
        XCTAssertEqual(XCTWaiter().wait(for: [back], timeout: 5), .completed,
                       "button stayed confirmed; label is \(save.label)")
        attach(named: "03-back-to-idle")
    }

    private func attach(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
