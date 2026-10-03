//
//  FeatureTipTests.swift
//  TopsterUITests
//

import XCTest

/// The feature tips. `-showAllTips YES` starts from an empty tip store and
/// shows every tip regardless of its rules; `-resetTips YES` starts from an
/// empty store and leaves the rules in charge. Every other UI suite launches
/// with `-hideAllTips YES` instead, so tips never cover their steps.
final class FeatureTipTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The swap tip shows over the grid and goes when closed. Its eligibility
    /// rule is not tested here, since `-showAllTips` bypasses it.
    ///
    /// Testing mode also ignores invalidation: `showAllTipsForTesting()`
    /// shows a closed tip again the next time TipKit re-evaluates it. So
    /// this test reports whether the tip comes back in the 10 s after the
    /// close and does not fail on it. The real path is held to staying
    /// closed by `testTheSwapTipStaysClosedOnTheRealPath`.
    /// Mutations: no swap tip view above the grid; a close control that does
    /// not retire the tip.
    func testTheSwapTipShowsAndCloses() throws {
        app = XCUIApplication()
        app.launchArguments = ["-resetForUITest", "YES", "-showAllTips", "YES"]
        app.launch()

        let swapTip = app.staticTexts["Hold an album to move it"]
        XCTAssertTrue(swapTip.waitForExistence(timeout: 20), "the swap tip never appeared over the grid")
        closeSwapTip()
        XCTAssertTrue(swapTip.waitForNonExistence(timeout: 5), "the swap tip stayed after its close")

        let cameBackAt = secondWhenTipReturns(swapTip)
        let report = cameBackAt.map { "showAllTips: the swap tip came back \($0) s after closing" }
            ?? "showAllTips: the swap tip stayed closed for 10 s"
        print(report)
        XCTContext.runActivity(named: report) { _ in }
    }

    /// The real path: an empty tip store, the rules in charge, and a grid
    /// with albums already down. The tip shows because the grid has two or
    /// more albums, and once closed it stays closed.
    /// Mutations: a rule that never passes; a close that does not invalidate;
    /// a grid change that brings a closed tip back.
    func testTheSwapTipStaysClosedOnTheRealPath() throws {
        app = XCUIApplication()
        app.launchArguments = ["-resetForUITest", "YES", "-resetTips", "YES",
                               "-FortyGridDict", "<\(GridSwapTests.seedHex)>"]
        app.launch()

        let swapTip = app.staticTexts["Hold an album to move it"]
        XCTAssertTrue(swapTip.waitForExistence(timeout: 20), "the swap tip never appeared over a grid with albums")
        closeSwapTip()
        XCTAssertTrue(swapTip.waitForNonExistence(timeout: 5), "the swap tip stayed after its close")

        if let second = secondWhenTipReturns(swapTip) {
            XCTFail("the swap tip came back after closing (\(second) s)")
        }
    }

    // MARK: - Helpers

    /// TipView stamps "TipView" over its children's identifiers, so the
    /// close control is found by its label.
    private func closeSwapTip() {
        app.buttons.matching(NSPredicate(format: "identifier == 'TipView' AND label == 'Close'")).firstMatch.tap()
    }

    /// Checks once a second for 10 s and returns the second the tip was
    /// back on screen, or nil if it never was.
    private func secondWhenTipReturns(_ tip: XCUIElement) -> Int? {
        for second in 1...10 {
            Thread.sleep(forTimeInterval: 1)
            if tip.exists { return second }
        }
        return nil
    }
}
