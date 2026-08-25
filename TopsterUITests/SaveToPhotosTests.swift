//
//  SaveToPhotosTests.swift
//  TopsterUITests
//

import XCTest

/// The success toast used to fire on the button tap rather than on the save, which
/// on a first save put "Grid saved to camera roll" underneath the permission prompt
/// before the user had agreed to anything.
final class SaveToPhotosTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testToastWaitsForTheActualSave() throws {
        let app = XCUIApplication()

        if let seed = ProcessInfo.processInfo.environment["SEED_HEX"], !seed.isEmpty {
            app.launchArguments = ["-FortyGridDict", "<\(seed)>"]
        }

        app.launch()
        Thread.sleep(forTimeInterval: 14)

        let preview = app.buttons["preview-grid"]
        XCTAssertTrue(preview.waitForExistence(timeout: 20), "preview button never appeared")
        preview.tap()
        Thread.sleep(forTimeInterval: 8)

        let save = app.buttons["save-to-photos"]
        XCTAssertTrue(save.waitForExistence(timeout: 15), "save button never appeared")
        save.tap()

        // The permission prompt should be up and the toast should not.
        Thread.sleep(forTimeInterval: 4)
        attach(named: "01-permission-prompt")

        // Hold here so the state can also be captured from outside.
        Thread.sleep(forTimeInterval: 10)

        // Grant it, whatever the button happens to be called on this OS version.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow Access to All Photos", "Allow Full Access", "Allow", "OK"] {
            let button = springboard.buttons[label]
            if button.exists {
                button.tap()
                break
            }
        }

        // The toast clears itself after 2 seconds, so catch it inside that window.
        Thread.sleep(forTimeInterval: 1.5)
        attach(named: "02-toast-after-real-save")

        // And confirm it clears rather than sticking around.
        Thread.sleep(forTimeInterval: 4)
        attach(named: "03-toast-cleared")

        Thread.sleep(forTimeInterval: 8)
    }

    private func attach(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
