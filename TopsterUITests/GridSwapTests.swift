//
//  GridSwapTests.swift
//  TopsterUITests
//

import XCTest

/// Hold and drag a cover to another slot, through the real gesture: a press
/// long enough to lift, a drag, a release. Every assertion reads the slots'
/// accessibility labels, which name the album each slot holds.
///
/// The grid is seeded through `-FortyGridDict`, so nothing here searches.
/// Covers are real Last.fm URLs; if they fail to load the labels still carry
/// the test.
final class GridSwapTests: XCTestCase {

    private var app: XCUIApplication!

    private static let okComputer = "OK Computer, Radiohead"
    private static let darkSide = "The Dark Side of the Moon, Pink Floyd"
    private static let kindOfBlue = "Kind of Blue, Miles Davis"
    private static let backToBlack = "Back to Black, Amy Winehouse"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Onto an album the two trade places; onto an empty slot the album moves
    /// and leaves its slot empty; outside every slot nothing changes.
    func testDraggingACoverSwapsMovesAndSpringsBack() throws {
        launch(layout: "twentyFive")

        XCTAssertEqual(slot(1).label, Self.okComputer)
        XCTAssertEqual(slot(2).label, Self.darkSide)
        XCTAssertEqual(slot(3).label, "Empty slot")

        drag(1, onto: slot(2))
        XCTAssertEqual(slot(1).label, Self.darkSide, "slot 1 did not take slot 2's album")
        XCTAssertEqual(slot(2).label, Self.okComputer, "slot 2 did not take slot 1's album")

        drag(1, onto: slot(3))
        XCTAssertEqual(slot(3).label, Self.darkSide, "the album did not move into the empty slot")
        XCTAssertEqual(slot(1).label, "Empty slot", "the album's old slot is not empty")
        XCTAssertEqual(slot(2).label, Self.okComputer, "a slot outside the move changed")

        // The navigation bar is outside every slot.
        drag(4, onto: app.navigationBars.firstMatch)
        XCTAssertEqual(slot(4).label, Self.kindOfBlue, "a drop outside the grid changed the slot")
        XCTAssertEqual(slot(3).label, Self.darkSide)
        XCTAssertEqual(slot(1).label, "Empty slot")
    }

    /// The held cover is drawn above the rows, so it can leave its own row.
    /// On the 42 that is also a drop between rows of different sizes.
    func testACoverDraggedAcrossRowsLandsOnTheFortyTwo() throws {
        launch(layout: "fortyTwo")

        XCTAssertEqual(slot(1).label, Self.okComputer)
        XCTAssertEqual(slot(13).label, Self.backToBlack)

        drag(1, onto: slot(13))

        XCTAssertEqual(slot(1).label, Self.backToBlack, "the row 3 album did not come up to row 1")
        XCTAssertEqual(slot(13).label, Self.okComputer, "the row 1 album did not land in row 3")
    }

    /// Five 96pt covers are wider than a phone, so slot 5 starts off screen.
    /// Held near the row's right edge, the cover scrolls the row continuously
    /// until slot 5 is in view and under the finger, and the drop lands there.
    func testHoldingAtARowsEdgeScrollsItToAHiddenSlot() throws {
        launch(layout: "twentyFive")

        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThan(slot(5).frame.maxX, window.maxX, "slot 5 is already on screen; nothing to scroll to")

        let source = slot(1)
        let edge = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: window.maxX - 30, dy: source.frame.midY))
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 1.5, thenDragTo: edge, withVelocity: .slow, thenHoldForDuration: 1.2)
        Thread.sleep(forTimeInterval: 1)

        XCTAssertTrue(slot(5).isHittable, "the row did not scroll slot 5 into view")
        XCTAssertEqual(slot(1).label, "Rumours, Fleetwood Mac", "the row never scrolled slot 5 under the finger")
        XCTAssertEqual(slot(5).label, Self.okComputer)
    }

    /// A finger that lands on a cover and moves at once is scrolling, not
    /// lifting. Starts inside the cover on purpose: the lift gesture lives on
    /// the cover, and on a real iPhone an earlier version of it swallowed
    /// every scroll that began there.
    func testADragStartingOnACoverScrollsItsRow() throws {
        launch(layout: "fortyTwo")

        XCTAssertFalse(slot(5).isHittable, "slot 5 is already on screen; nothing to scroll to")
        fling(from: slot(2), by: CGVector(dx: -300, dy: 0))

        XCTAssertTrue(slot(5).isHittable, "the row did not scroll from a drag that started on a cover")
        XCTAssertEqual(slot(2).label, Self.darkSide, "a scroll moved an album")
    }

    /// The same for the page: a vertical drag that starts on a cover scrolls
    /// the grid. The 42 is taller than the space it has.
    func testADragStartingOnACoverScrollsTheGrid() throws {
        launch(layout: "fortyTwo")

        let top = slot(33).frame.minY
        fling(from: slot(13), by: CGVector(dx: 0, dy: -300))

        XCTAssertLessThan(slot(33).frame.minY, top - 10,
                          "the grid did not scroll from a drag that started on a cover")
        XCTAssertEqual(slot(13).label, Self.backToBlack, "a scroll moved an album")
    }

    /// A quick tap on a cover opens search, as it always has. A hold let go
    /// in place lifts the cover and puts it back, which is not a tap.
    func testATapOpensSearchAndAHoldInPlaceDoesNot() throws {
        launch(layout: "fortyTwo")

        slot(13).press(forDuration: 1.2)
        XCTAssertFalse(app.textFields["album-search-field"].waitForExistence(timeout: 2),
                       "holding a cover opened search")
        XCTAssertEqual(slot(13).label, Self.backToBlack)

        slot(13).tap()
        XCTAssertTrue(app.textFields["album-search-field"].waitForExistence(timeout: 8),
                      "a tap on a cover no longer opens search")
    }

    /// VoiceOver reads the slot number from the value, so "Moved to slot 3"
    /// has something to refer to. The label stays the album, since this suite
    /// and the walkthrough find slots by it.
    ///
    /// The Move to previous and next slot actions themselves cannot be
    /// invoked from XCUITest: Xcode 26.6's XCUIAutomation has no public API
    /// for custom accessibility actions. SlotSwapTests covers them instead.
    func testACoverCarriesItsSlotNumberForVoiceOver() throws {
        launch(layout: "twentyFive")

        XCTAssertEqual(slot(1).label, Self.okComputer)
        XCTAssertEqual(slot(1).value as? String, "slot 1")
        XCTAssertEqual(slot(4).value as? String, "slot 4")
    }

    // MARK: - Helpers

    private func launch(layout: String) {
        app = XCUIApplication()
        app.launchArguments = ["-FortyGridDict", "<\(Self.seedHex)>",
                               "-storedSavedGrids", "<5b5d>",
                               "-activeGridType", layout,
                               "-exportLabels", "none"]
        // Tips have their own suite; here they would cover the steps.
        app.launchArguments += ["-hideAllTips", "YES"]
        app.launch()
        XCTAssertTrue(slot(1).waitForExistence(timeout: 20), "the grid never appeared")
    }

    private func slot(_ key: Int) -> XCUIElement {
        app.descendants(matching: .any)["slot-\(key)"]
    }

    /// Holds well past the 0.4 s lift, drags slowly, and rests over the
    /// target before letting go, the way a person would.
    private func drag(_ key: Int, onto target: XCUIElement) {
        let source = slot(key)
        XCTAssertTrue(source.waitForExistence(timeout: 10), "no slot \(key)")
        XCTAssertTrue(target.waitForExistence(timeout: 10), "no drop target")
        source.press(forDuration: 1.5, thenDragTo: target,
                     withVelocity: .slow, thenHoldForDuration: 1.5)
        // The cover settles in 0.3 s.
        Thread.sleep(forTimeInterval: 1)
    }

    /// Touch down inside `element` and move straight away, fast, the way a
    /// flick starts. No hold, so nothing should lift.
    private func fling(from element: XCUIElement, by offset: CGVector) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0, thenDragTo: start.withOffset(offset),
                    withVelocity: .fast, thenHoldForDuration: 0)
        Thread.sleep(forTimeInterval: 1.5)
    }

    // MARK: - Seed

    private struct Cover {
        let name: String
        let artist: String
        let art: String
    }

    /// Slot to album. Everything not listed is empty, including slot 3 on
    /// purpose, as the target of the move.
    private static let covers: [Int: Cover] = [
        1: Cover(name: "OK Computer", artist: "Radiohead", art: "62d26c6cb4ac4bdccb8f3a2a0fd55421.png"),
        2: Cover(name: "The Dark Side of the Moon", artist: "Pink Floyd", art: "d4bdd038cacbec705e269edb0fd38419.png"),
        4: Cover(name: "Kind of Blue", artist: "Miles Davis", art: "e345e60dfec207641798c02ae8071280.png"),
        5: Cover(name: "Rumours", artist: "Fleetwood Mac", art: "349d64820e124b77cb5275ab03042693.png"),
        6: Cover(name: "Abbey Road", artist: "The Beatles", art: "f304ba0296794c6fc9d0e1cccd194ed0.jpg"),
        8: Cover(name: "good kid, m.A.A.d city", artist: "Kendrick Lamar", art: "48628c6af67db437b0b9ff156b2c1085.jpg"),
        9: Cover(name: "Discovery", artist: "Daft Punk", art: "1340e9e1082cf0dc748583b7eefce6d5.jpg"),
        13: Cover(name: "Back to Black", artist: "Amy Winehouse", art: "5e8b279da10957d060253256c8302f8f.png"),
    ]

    /// The stored grid's JSON shape, hex-encoded for the launch argument.
    /// `FeatureTipTests` seeds its grid with it too.
    static var seedHex: String {
        var grid: [String: Any] = [:]
        for key in 1...42 {
            guard let cover = covers[key] else {
                grid[String(key)] = NSNull()
                continue
            }
            let base = "https://lastfm-img.freetls.fastly.net/i/u/"
            grid[String(key)] = [
                "name": cover.name, "artist": cover.artist, "url": "",
                "streamable": "0", "mbid": "",
                "image": [["#text": base + "174s/" + cover.art, "size": "large"],
                          ["#text": base + "300x300/" + cover.art, "size": "extralarge"]],
            ]
        }
        let data = try! JSONSerialization.data(withJSONObject: grid)
        return data.map { byte in String(format: "%02x", byte) }.joined()
    }
}
