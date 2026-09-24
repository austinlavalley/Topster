//
//  MainFlowWalkthrough.swift
//  TopsterUITests
//

import XCTest

/// One new user, head to toe: an empty 25, albums found through the real
/// search, a replacement and a removal, every layout, every export option,
/// a save to Photos, and a saved grid closed and reopened.
///
/// 1.7.1 and 1.7.2 crashed opening the export for a 25 with ten or more
/// albums, an empty bottom row and the list on. Every test passed, because
/// every test that rendered the export used a full grid. This walks the grid
/// people actually have, part filled, through everything they can do to it,
/// and fails with the step's name if the app dies anywhere along the way.
///
/// Searches hit Last.fm for real. An outage fails this test, which is
/// intended: search is the way into the app.
final class MainFlowWalkthrough: XCTestCase {

    private var app: XCUIApplication!

    /// Album titles, searched in this order into slots 1 through 12. Titles
    /// rather than artists, so the result to tap can be matched by name and a
    /// result from a half-typed query is never the one tapped.
    private let albums = ["In Rainbows", "Rumours", "Blonde", "Abbey Road", "Illmatic", "Currents",
                          "Nevermind", "Discovery", "Punisher", "Channel Orange", "Kid A", "Ctrl"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testANewUserBuildsExportsAndSavesAGrid() throws {
        app = XCUIApplication()
        app.launchArguments = ["-resetForUITest", "YES"]
        app.launch()

        step("a fresh launch opens an empty 25") {
            XCTAssertTrue(slot(1).waitForExistence(timeout: 20), "the grid never appeared")
            XCTAssertTrue(slot(25).exists, "the 25 is missing slots")
            XCTAssertFalse(slot(26).exists, "a fresh launch did not open on the 25")
            XCTAssertEqual(slot(1).label, "Empty slot")
            XCTAssertFalse(app.buttons["preview-grid"].isEnabled, "Preview is enabled on an empty grid")
        }

        // Twelve on a 25: two full rows, two albums in the third, the bottom
        // rows empty. The state most grids are in most of the time.
        for (index, title) in albums.enumerated() {
            step("search for \(title) and place it in slot \(index + 1)") {
                place(title, in: index + 1)
            }
        }

        step("replace the album in slot 3") {
            place("Blue", in: 3)
        }

        step("remove the album in slot 4") {
            tapSlot(4)
            let remove = app.buttons["Remove"]
            XCTAssertTrue(remove.waitForExistence(timeout: 10), "no Remove button for a filled slot")
            remove.tap()
            dismissSearchSheet()
            XCTAssertEqual(slot(4).label, "Empty slot")
        }

        for layout in ["twentyFive", "twenty", "twentyWide", "fortyTwo"] {
            step("switch to the \(layout) layout") {
                chooseLayout(layout)
            }
            step("export the \(layout) with every option") {
                exportEveryWay()
            }
        }

        step("switch back to the 25") {
            chooseLayout("twentyFive")
        }

        step("save the 25 to Photos with the list on") {
            openExport()
            app.segmentedControls["export-titles"].buttons["List"].tap()
            assertAlive("choosing List")
            saveToPhotos()
            closeExport()
        }

        let firstAlbum = slot(1).label

        step("save the grid") {
            let save = app.buttons["Save grid"]
            XCTAssertTrue(save.waitForExistence(timeout: 5))
            save.tap()
            assertAlive("saving the grid")
            app.tabBars.buttons["Saved"].tap()
            XCTAssertTrue(app.descendants(matching: .any)["saved-grid-0"].waitForExistence(timeout: 10),
                          "the saved grid is not in the Saved tab")
            app.tabBars.buttons["Grid"].tap()
        }

        step("start a new grid") {
            menu("New grid")
            XCTAssertEqual(slot(1).label, "Empty slot", "New grid left albums behind")
            XCTAssertFalse(app.buttons["preview-grid"].isEnabled)
        }

        step("reopen the saved grid and export it") {
            app.tabBars.buttons["Saved"].tap()
            let card = app.descendants(matching: .any)["saved-grid-0"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            card.tap()
            app.tabBars.buttons["Grid"].tap()
            XCTAssertTrue(slot(1).waitForExistence(timeout: 10))
            XCTAssertEqual(slot(1).label, firstAlbum, "the saved grid did not come back")
            XCTAssertEqual(slot(4).label, "Empty slot", "the saved grid lost its gap")
            openExport()
            closeExport()
        }

        step("remove the saved grid") {
            menu("Remove grid from saved")
            app.tabBars.buttons["Saved"].tap()
            XCTAssertTrue(app.staticTexts["No grids saved yet"].waitForExistence(timeout: 10),
                          "the saved grid is still listed")
            app.tabBars.buttons["Grid"].tap()
        }
    }

    // MARK: - Steps

    private func place(_ title: String, in key: Int) {
        tapSlot(key)

        let field = app.textFields["album-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "the search sheet did not open")
        field.tap()
        field.typeText(title)

        let result = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'search-result' AND label BEGINSWITH[c] %@", title))
            .firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30), "no result for \(title)")
        let placed = result.label
        result.tap()

        XCTAssertTrue(field.waitForNonExistence(timeout: 10), "the search sheet stayed open")
        XCTAssertEqual(slot(key).label, placed, "slot \(key) does not hold what was tapped")
    }

    /// Removing an album leaves the sheet open, so it is closed the way a
    /// person closes it: dragged down by its top edge, or failing that, a tap
    /// on the dimmed grid above it.
    private func dismissSearchSheet() {
        let field = app.textFields["album-search-field"]
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.17))
        top.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        if !field.waitForNonExistence(timeout: 3) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.06)).tap()
        }
        XCTAssertTrue(field.waitForNonExistence(timeout: 10), "the search sheet did not close")
    }

    private func chooseLayout(_ layout: String) {
        menu("Change grid layout")
        let option = app.buttons["layout-\(layout)"]
        XCTAssertTrue(option.waitForExistence(timeout: 5), "no \(layout) option")
        option.tap()
        XCTAssertTrue(option.waitForNonExistence(timeout: 5), "the layout sheet did not close")
        assertAlive("switching to \(layout)")
        XCTAssertTrue(slot(1).exists)
    }

    /// Every background with every titles option, which is every export the
    /// sheet can make of this grid.
    private func exportEveryWay() {
        openExport()
        let background = app.segmentedControls["export-background"]
        let titles = app.segmentedControls["export-titles"]
        for shade in ["Light", "Dark"] {
            background.buttons[shade].tap()
            for option in ["None", "Overlay", "List"] {
                titles.buttons[option].tap()
                assertAlive("rendering \(shade), \(option)")
                XCTAssertTrue(titles.buttons[option].isSelected)
            }
        }
        background.buttons["Light"].tap()
        titles.buttons["None"].tap()
        closeExport()
    }

    /// Waits for the button's confirmation rather than the tap, and grants
    /// Photos access if this simulator has not been asked yet.
    private func saveToPhotos() {
        let save = app.buttons["save-to-photos"]
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        save.tap()

        var confirmed = false
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline && !confirmed {
            if springboard.alerts.firstMatch.exists {
                for label in ["Allow Access to All Photos", "Allow Full Access", "Allow", "OK"] {
                    let button = springboard.buttons[label]
                    if button.exists {
                        button.tap()
                        break
                    }
                }
            }
            confirmed = save.label.contains("Saved to Photos")
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertTrue(confirmed, "Save to Photos never confirmed; the button says \(save.label)")
    }

    // MARK: - Helpers

    private func step(_ name: String, _ body: () -> Void) {
        XCTContext.runActivity(named: name) { _ in
            body()
            assertAlive(name)
        }
    }

    /// A crash shows up as the app leaving the foreground. The export renders
    /// on the main thread right after an option changes, so a short pause is
    /// enough for a trap to land before the check.
    private func assertAlive(_ doing: String) {
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(app.state, .runningForeground, "the app stopped while \(doing)")
    }

    private func slot(_ key: Int) -> XCUIElement {
        app.descendants(matching: .any)["slot-\(key)"]
    }

    /// Near the corner, not the middle: an empty slot draws its plus over the
    /// middle, and the tap belongs to the square underneath it.
    private func tapSlot(_ key: Int) {
        let element = slot(key)
        XCTAssertTrue(element.waitForExistence(timeout: 10), "no slot \(key)")
        scrollIntoView(element)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2)).tap()
    }

    /// Each row scrolls sideways, and five 96pt squares are wider than a
    /// phone, so the last slot in a row starts off screen. Drags the row the
    /// way a person would until the slot is fully in view.
    private func scrollIntoView(_ element: XCUIElement) {
        let window = app.windows.firstMatch.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        for _ in 0..<6 {
            let frame = element.frame
            let dx: CGFloat
            if frame.maxX > window.maxX - 8 {
                dx = -min(frame.maxX - window.maxX + 40, 240)
            } else if frame.minX < window.minX + 8 {
                dx = min(window.minX - frame.minX + 40, 240)
            } else {
                return
            }
            let start = origin.withOffset(CGVector(dx: window.midX, dy: frame.midY))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: dx, dy: 0)))
        }
        XCTFail("slot \(element.identifier) never scrolled into view")
    }

    private func menu(_ item: String) {
        app.buttons["grid-menu"].tap()
        let button = app.buttons[item]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "no \(item) in the menu")
        button.tap()
    }

    private func openExport() {
        let preview = app.buttons["preview-grid"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        preview.tap()
        XCTAssertTrue(app.buttons["save-to-photos"].waitForExistence(timeout: 20), "the export never rendered")
        assertAlive("opening the export")
    }

    private func closeExport() {
        app.buttons["export-close"].tap()
        XCTAssertTrue(app.buttons["export-close"].waitForNonExistence(timeout: 5), "the export sheet did not close")
    }
}
