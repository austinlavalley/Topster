//
//  GridPaddingTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// The grid views render cells by slicing the stored dictionary, so a grid
/// missing keys silently loses rows on screen. A 20-key dict labelled fortyTwo
/// did exactly that on a test device: one bad save propagated into every grid
/// saved after it. Padding on load is the self-heal.
final class GridPaddingTests: XCTestCase {

    private func album(_ name: String) -> Album {
        Album(name: name, artist: "Artist", url: "", image: [], streamable: "0", mbid: "")
    }

    /// The corrupted shape as found: 20 keys of nothing on a fortyTwo grid.
    func testATruncatedGridIsRestoredToItsFullSlotCount() {
        let corrupted: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...20).map { key in (key, Album?.none) })

        let healed = FortyScrollGridViewModel.padded(corrupted, to: GridType.fortyTwo.slotCount)

        XCTAssertEqual(healed.count, 42)
    }

    func testExistingAlbumsSurvivePadding() {
        let sparse: [Int: Album?] = [3: album("Blue"), 7: nil]

        let healed = FortyScrollGridViewModel.padded(sparse, to: 42)

        XCTAssertEqual(healed.count, 42)
        XCTAssertEqual(healed[3]??.name, "Blue")
    }

    func testAFullGridIsUntouched() {
        var full: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...42).map { key in (key, Album?.none) })
        full[1] = album("Kid A")

        let healed = FortyScrollGridViewModel.padded(full, to: 42)

        XCTAssertEqual(healed.count, 42)
        XCTAssertEqual(healed[1]??.name, "Kid A")
    }

    /// A twenty-type grid legitimately has 20 keys; padding to its own slot
    /// count must not grow it into something the layout never shows.
    func testASmallerLayoutKeepsItsOwnSlotCount() {
        let twenty: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...20).map { key in (key, Album?.none) })

        let healed = FortyScrollGridViewModel.padded(twenty, to: GridType.twenty.slotCount)

        XCTAssertEqual(healed.count, 20)
    }

    /// Each layout's slot count is what its master view actually renders; these
    /// numbers mirror the prefix() slices in GridContent.
    func testSlotCountsMatchTheLayouts() {
        XCTAssertEqual(GridType.fortyTwo.slotCount, 42)
        XCTAssertEqual(GridType.twenty.slotCount, 20)
        XCTAssertEqual(GridType.twentyWide.slotCount, 20)
        XCTAssertEqual(GridType.twentyFive.slotCount, 25)
    }

    // MARK: - Layout persistence

    /// The grid's contents always survived relaunch; the chosen layout did not,
    /// so an unsaved twentyFive grid came back displayed as fortyTwo.
    func testTheChosenLayoutSurvivesRelaunch() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "grid-layout-test"))
        suite.removePersistentDomain(forName: "grid-layout-test")
        defer { suite.removePersistentDomain(forName: "grid-layout-test") }

        let firstLaunch = FortyScrollGridViewModel(defaults: suite)
        XCTAssertEqual(firstLaunch.activeGridType, .fortyTwo, "default before any choice")

        firstLaunch.activeGridType = .twentyFive

        let secondLaunch = FortyScrollGridViewModel(defaults: suite)
        XCTAssertEqual(secondLaunch.activeGridType, .twentyFive)
    }

    /// A stored value that no longer maps to a layout must not crash or stick;
    /// it falls back to the default.
    func testAnUnknownStoredLayoutFallsBackToTheDefault() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "grid-layout-test"))
        suite.removePersistentDomain(forName: "grid-layout-test")
        defer { suite.removePersistentDomain(forName: "grid-layout-test") }

        suite.set("thirteenDiagonal", forKey: "activeGridType")

        let vm = FortyScrollGridViewModel(defaults: suite)
        XCTAssertEqual(vm.activeGridType, .fortyTwo)
    }


    /// End to end through the stored format: the exact JSON shape found in the
    /// broken container decodes and heals.
    func testTheStoredJSONShapeDecodesAndHeals() throws {
        let json = "{" + (1...20).map { key in "\"\(key)\": null" }.joined(separator: ",") + "}"
        let decoded = try JSONDecoder().decode([Int: Album?].self, from: Data(json.utf8))

        XCTAssertEqual(decoded.count, 20)
        XCTAssertEqual(FortyScrollGridViewModel.padded(decoded, to: 42).count, 42)
    }
}
