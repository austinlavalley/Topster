//
//  SlotSwapTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// Drag-to-swap's model half. Dropping a held cover calls `swapSlots`, and this
/// is everything it may and may not do to the grid.
///
/// The view model reads its grid from injected defaults, but writes the grid
/// and `currentActiveGrid` through `@AppStorage`, which is the host app's
/// standard defaults. Those two keys are saved before each test and put back
/// after, so running the suite does not rearrange the simulator's grid.
final class SlotSwapTests: XCTestCase {

    private let suiteName = "slot-swap-test"
    private var suite: UserDefaults!
    private var savedGrid: Any?
    private var savedActive: Any?

    override func setUpWithError() throws {
        savedGrid = UserDefaults.standard.object(forKey: "FortyGridDict")
        savedActive = UserDefaults.standard.object(forKey: "currentActiveGrid")
        // Cleared so testTheMoveIsStored cannot pass on what was already there.
        UserDefaults.standard.removeObject(forKey: "FortyGridDict")

        suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        suite.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: suiteName)
        restore(savedGrid, forKey: "FortyGridDict")
        restore(savedActive, forKey: "currentActiveGrid")
    }

    private func restore(_ value: Any?, forKey key: String) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func album(_ name: String) -> Album {
        Album(name: name, artist: "Artist", url: "", image: [], streamable: "0", mbid: "")
    }

    /// A 42 with Blue in slot 1, Kid A in slot 2, and every other slot empty,
    /// opened on a saved grid so clearing `currentActiveGrid` is visible.
    private func grid() throws -> FortyScrollGridViewModel {
        var stored: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...42).map { key in (key, Album?.none) })
        stored[1] = album("Blue")
        stored[2] = album("Kid A")
        suite.set(try JSONEncoder().encode(stored), forKey: "FortyGridDict")
        suite.set("fortyTwo", forKey: "activeGridType")

        let vm = FortyScrollGridViewModel(defaults: suite)
        vm.currentActiveGrid = 0
        return vm
    }

    private func name(_ vm: FortyScrollGridViewModel, _ key: Int) -> String? {
        vm.FortyGridDict[key]??.name
    }

    /// Fails if either write is dropped, which would leave one album in both
    /// slots, or if the body is emptied.
    func testDroppingOnAnAlbumTradesTheTwo() throws {
        let vm = try grid()

        vm.swapSlots(1, 2)

        XCTAssertEqual(name(vm, 1), "Kid A")
        XCTAssertEqual(name(vm, 2), "Blue")
    }

    /// Fails if a move empties the origin with a literal `grid[a] = nil`,
    /// which deletes the key instead of emptying the slot.
    func testDroppingOnAnEmptySlotMovesTheAlbumAndEmptiesTheOrigin() throws {
        let vm = try grid()

        vm.swapSlots(1, 7)

        XCTAssertEqual(name(vm, 7), "Blue")
        XCTAssertTrue(vm.FortyGridDict.keys.contains(1), "slot 1 was deleted, not emptied")
        XCTAssertNil(name(vm, 1))
        XCTAssertEqual(name(vm, 2), "Kid A", "an uninvolved slot changed")
    }

    /// Fails if the `a != b` guard goes: the grid would survive, but the
    /// open saved grid would be detached for a drop that changed nothing.
    func testDroppingOnItsOwnSlotChangesNothing() throws {
        let vm = try grid()
        let before = vm.FortyGridDict.mapValues { entry in entry?.name }

        vm.swapSlots(1, 1)

        XCTAssertEqual(vm.FortyGridDict.mapValues { entry in entry?.name }, before)
        XCTAssertEqual(vm.currentActiveGrid, 0)
    }

    /// Fails if the empty-source guard goes: the empty slot's nothing would be
    /// moved onto Kid A, deleting it from the grid.
    func testAnEmptySlotCannotBeMoved() throws {
        let vm = try grid()
        let before = vm.FortyGridDict.mapValues { entry in entry?.name }

        vm.swapSlots(9, 2)
        vm.swapSlots(1, 99)

        XCTAssertEqual(vm.FortyGridDict.mapValues { entry in entry?.name }, before)
        XCTAssertEqual(vm.currentActiveGrid, 0)
    }

    /// Fails if `currentActiveGrid = nil` is dropped: the grid on screen would
    /// no longer match the saved grid it claims to be.
    func testAMoveDetachesTheOpenSavedGrid() throws {
        let vm = try grid()

        vm.swapSlots(2, 30)

        XCTAssertNil(vm.currentActiveGrid)
    }

    /// Fails on the literal-nil write as well, from the other side: a layout
    /// renders by slicing the dictionary, so a missing key is a missing cell.
    func testEveryKeySurvivesAMoveAndASwap() throws {
        let vm = try grid()

        vm.swapSlots(1, 42)
        vm.swapSlots(2, 42)

        XCTAssertEqual(vm.FortyGridDict.count, 42)
        XCTAssertEqual(Set(vm.FortyGridDict.keys), Set(1...42))
        XCTAssertEqual(name(vm, 42), "Kid A")
        XCTAssertEqual(name(vm, 2), "Blue")
        XCTAssertNil(name(vm, 1))
    }

    // MARK: - VoiceOver moves

    /// XCUITest has no public way to invoke a custom accessibility action
    /// (checked against Xcode 26.6's XCUIAutomation), so the move actions are
    /// pinned here. Fails if an end slot offers a move off the layout, or a
    /// middle slot loses one.
    func testMoveActionsStopAtTheEndsOfTheLayout() {
        XCTAssertNil(SlotStep.neighbour(of: 1, by: -1, slotCount: 25), "slot 1 offers a previous slot")
        XCTAssertEqual(SlotStep.neighbour(of: 1, by: 1, slotCount: 25), 2)
        XCTAssertEqual(SlotStep.neighbour(of: 13, by: -1, slotCount: 25), 12)
        XCTAssertEqual(SlotStep.neighbour(of: 13, by: 1, slotCount: 25), 14)
        XCTAssertEqual(SlotStep.neighbour(of: 25, by: -1, slotCount: 25), 24)
        XCTAssertNil(SlotStep.neighbour(of: 25, by: 1, slotCount: 25), "slot 25 offers slot 26 on a 25")
        XCTAssertEqual(SlotStep.neighbour(of: 25, by: 1, slotCount: 42), 26, "the 42 cut off at 25")
    }

    // MARK: - What the cells draw while covers are in flight

    /// On a swap both slots keep ghosts of what they held before the drop
    /// while the covers fly. Fails if either key is left out, which repaints
    /// that slot with its new album before anything lands on it.
    func testASwapLeavesGhostsOfBothOldAlbums() throws {
        let vm = try grid()

        let overrides = SlotDrag.landingOverrides(source: 1, target: 2, grid: vm.FortyGridDict)

        XCTAssertEqual(Set(overrides.keys), [1, 2])
        XCTAssertEqual(overrides[1]??.name, "Blue")
        XCTAssertEqual(overrides[2]??.name, "Kid A")
    }

    /// On a move the empty target stays empty until the cover lands. Fails
    /// if the empty target gets no override (skipped, or written as a literal
    /// nil through the subscript), which lets the album appear under the
    /// incoming cover.
    func testAMoveKeepsTheTargetEmptyUntilLanding() throws {
        let vm = try grid()

        let overrides = SlotDrag.landingOverrides(source: 1, target: 7, grid: vm.FortyGridDict)

        XCTAssertEqual(Set(overrides.keys), [1, 7])
        XCTAssertEqual(overrides[1]??.name, "Blue")
        XCTAssertNotNil(overrides[7], "the empty target has no override")
        XCTAssertNil(overrides[7] ?? nil)
    }

    /// Fails if the write goes to `FortyGridDict` instead of
    /// `EditableFortyGridDict`: the move would show, then vanish on relaunch.
    func testTheMoveIsStored() throws {
        let vm = try grid()

        vm.swapSlots(1, 2)

        let data = try XCTUnwrap(UserDefaults.standard.data(forKey: "FortyGridDict"))
        let stored = try JSONDecoder().decode([Int: Album?].self, from: data)
        XCTAssertEqual(stored[1]??.name, "Kid A")
        XCTAssertEqual(stored[2]??.name, "Blue")
    }
}
