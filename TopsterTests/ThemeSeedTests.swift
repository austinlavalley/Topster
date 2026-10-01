//
//  ThemeSeedTests.swift
//  TopsterTests
//

import UIKit
import XCTest
@testable import Topster

/// A fresh install starts with the dark mode toggle matching the phone. Anyone
/// who already has a choice stored, or a grid, keeps what they had.
final class ThemeSeedTests: XCTestCase {

    func testFreshInstallOnDarkPhoneSeedsDark() {
        XCTAssertEqual(TopsterApp.seededDarkMode(stored: nil, hasGrid: false, systemStyle: .dark),
                       true)
    }

    func testFreshInstallOnLightPhoneSeedsLight() {
        XCTAssertEqual(TopsterApp.seededDarkMode(stored: nil, hasGrid: false, systemStyle: .light),
                       false)
    }

    /// A stored choice wins whatever the phone says, including a launch
    /// argument that sets the key for a test.
    func testStoredChoiceIsLeftAlone() {
        for stored in [true, false] {
            for style in [UIUserInterfaceStyle.dark, .light, .unspecified] {
                for hasGrid in [true, false] {
                    XCTAssertNil(TopsterApp.seededDarkMode(stored: stored, hasGrid: hasGrid,
                                                           systemStyle: style),
                                 "stored \(stored), style \(style.rawValue), grid \(hasGrid)")
                }
            }
        }
    }

    /// An existing user who never touched the toggle has no key but has a
    /// grid. They were on light and stay there, even on a dark phone.
    func testExistingUserWithoutKeyIsLeftAlone() {
        XCTAssertNil(TopsterApp.seededDarkMode(stored: nil, hasGrid: true, systemStyle: .dark))
        XCTAssertNil(TopsterApp.seededDarkMode(stored: nil, hasGrid: true, systemStyle: .light))
    }
}
