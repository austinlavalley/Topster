//
//  FeatureTipsTests.swift
//  TopsterTests
//

import XCTest
import TipKit
@testable import Topster

/// The swap tip's two inputs, as the view model feeds them. The rule itself
/// is TipKit's `#Rule`, which cannot call a helper, so these test what the
/// rule reads rather than a copy of it. The host app configures TipKit at
/// launch, so the parameters are live here.
final class FeatureTipsTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suite = "FeatureTipsTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func album(_ name: String) -> Album {
        Album(name: name, artist: "Artist", url: "",
              image: [AlbumImage(text: "https://example.com/300.png", size: "extralarge")],
              streamable: "0", mbid: "")
    }

    /// Placing albums moves the count the tip waits on. Mutation: dropping
    /// the update from the grid's didSet leaves it at 0.
    func testPlacementsCountTowardTheSwapTip() {
        let vm = FortyScrollGridViewModel(defaults: defaults)
        XCTAssertEqual(SwapTip.placedAlbums, 0)

        vm.addAlbumToGrid(album: album("One"), at: 1)
        vm.addAlbumToGrid(album: album("Two"), at: 2)

        XCTAssertEqual(SwapTip.placedAlbums, 2)
    }

    /// The grid's write leaves the tip up: it retires once the covers have
    /// landed, from `SlotDrag`, so it does not leave over flying covers.
    /// Mutation: `swapSlots` reporting the swap itself sets `hasSwapped`.
    func testTheSwapWriteLeavesTheSwapTipUp() {
        let vm = FortyScrollGridViewModel(defaults: defaults)
        vm.addAlbumToGrid(album: album("One"), at: 1)
        SwapTip.hasSwapped = false

        vm.swapSlots(1, 2)

        XCTAssertFalse(SwapTip.hasSwapped)
    }

    /// Acting on the tip retires it and marks the `acted` event as sent, so
    /// later swaps send nothing. Mutation: an `acted` that does not set
    /// `hasSwapped`; one that does not remember it has reported.
    func testActingRetiresTheSwapTipOnce() {
        SwapTip.hasSwapped = false

        FeatureTips.acted(.swap, defaults: defaults)

        XCTAssertTrue(SwapTip.hasSwapped)
        XCTAssertTrue(defaults.bool(forKey: "featureTip.acted.swap"))
        SwapTip.hasSwapped = false
    }
}
