//
//  ExportListTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// The sidebar numbers the albums that were placed, not the slots they sit
/// in, and groups them by grid row so each group can sit level with its row.
/// Decided in conversation on 4 Sep 2026: slot numbering jumps at every hidden
/// row, and a list that counts to 42 beside eleven covers is worse than no
/// list.
final class ExportListTests: XCTestCase {

    private func album(_ artist: String, _ name: String) -> Album {
        Album(name: name, artist: artist, url: "", image: [], streamable: "0", mbid: "")
    }

    /// Every layout's row shape has to add up to its slot count, or the list
    /// silently drops the last row.
    func testRowShapesCoverEverySlot() {
        for type in [GridType.fortyTwo, .twenty, .twentyWide, .twentyFive] {
            XCTAssertEqual(type.rowShape.reduce(0, +), type.slotCount, "\(type)")
        }
    }

    /// Holes in a row do not leave holes in the numbering.
    func testNumberingSkipsEmptySlots() {
        let grid: [Int: Album?] = [
            1: album("Guitar Slim", "Sufferin' Mind"),
            2: nil,
            3: album("Bo Diddley", "Bo Diddley"),
            4: nil,
            5: album("This Heat", "Made Available"),
        ]

        let groups = ExportList.groups(grid: grid, shape: [5])

        XCTAssertEqual(groups, [[
            ExportListLine(number: 1, text: "Guitar Slim – Sufferin' Mind"),
            ExportListLine(number: 2, text: "Bo Diddley – Bo Diddley"),
            ExportListLine(number: 3, text: "This Heat – Made Available"),
        ]])
    }

    /// A row with nothing in it still gets a group, an empty one, so the
    /// sidebar can hold its place on layouts that draw the row blank. The
    /// numbering carries straight across it.
    func testAnEmptyRowKeepsItsPlaceAndLeavesNoGap() {
        var grid: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...15).map { key in (key, Album?.none) })
        grid[2] = album("A", "One")
        grid[11] = album("B", "Two")
        grid[15] = album("C", "Three")

        let groups = ExportList.groups(grid: grid, shape: [5, 5, 5])

        XCTAssertEqual(groups.map { group in group.map(\.number) }, [[1], [], [2, 3]])
    }

    /// A full 42 grid lists 42 entries across six groups shaped like the rows.
    func testAFullGridGroupsByRow() {
        let grid: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...42).map { key in (key, album("Artist \(key)", "Album \(key)")) })

        let groups = ExportList.groups(grid: grid, shape: GridType.fortyTwo.rowShape)

        XCTAssertEqual(groups.map(\.count), [5, 5, 6, 6, 10, 10])
        XCTAssertEqual(groups.last?.last?.number, 42)
        XCTAssertEqual(groups.last?.last?.text, "Artist 42 – Album 42")
    }

    func testAnEmptyGridListsNothing() {
        let grid: [Int: Album?] = Dictionary(
            uniqueKeysWithValues: (1...20).map { key in (key, Album?.none) })

        let groups = ExportList.groups(grid: grid, shape: GridType.twenty.rowShape)

        XCTAssertTrue(groups.allSatisfy(\.isEmpty))
    }

    /// Row heights are the tile size: the canvas width shared between the
    /// row's columns, less the spacing between them. Checked against the
    /// numbers the export views produce, so a change to either shows here.
    func testRowHeightsMatchTheTilesTheExportDraws() {
        let fixed = ExportList.rowHeights(shape: GridType.twentyFive.rowShape, width: 3366, spacing: 24)
        XCTAssertEqual(fixed, Array(repeating: 654, count: 5))

        let dynamic = ExportList.rowHeights(shape: GridType.fortyTwo.rowShape, width: 3366, spacing: 24)
        XCTAssertEqual(dynamic.map { height in Int(height) }, [654, 654, 541, 541, 315, 315])
    }

    private func fullGrid(_ count: Int) -> [Int: Album?] {
        Dictionary(uniqueKeysWithValues: (1...count).map { key in (key, album("A \(key)", "B \(key)")) })
    }

    /// The 42 reads as three bands of tile size, two rows each, so its list
    /// has three sections of 10, 12 and 20, each placed at its band.
    func testTheDynamicLayoutSectionsByTileSize() {
        let shape = GridType.fortyTwo.rowShape
        let sections = ExportList.sections(
            groups: ExportList.groups(grid: fullGrid(42), shape: shape),
            rowHeights: ExportList.rowHeights(shape: shape, width: 3366, spacing: 24),
            rowsPerSection: GridType.fortyTwo.rowsPerListSection,
            hidesEmptyRows: true, spacing: 24)

        XCTAssertEqual(sections.map { section in section.lines.count }, [10, 12, 20])
        XCTAssertEqual(sections.map { section in Int(section.top) }, [0, 1356, 2486])
        XCTAssertEqual(sections.map { section in Int(section.height) }, [1332, 1106, 654])
        XCTAssertEqual(sections.last?.lines.first?.number, 23)
    }

    /// The fixed layouts read as rows, so every row is its own section.
    func testAFixedLayoutSectionsByRow() {
        let shape = GridType.twentyFive.rowShape
        let sections = ExportList.sections(
            groups: ExportList.groups(grid: fullGrid(25), shape: shape),
            rowHeights: ExportList.rowHeights(shape: shape, width: 3366, spacing: 24),
            rowsPerSection: GridType.twentyFive.rowsPerListSection,
            hidesEmptyRows: false, spacing: 24)

        XCTAssertEqual(sections.map { section in section.lines.count }, [5, 5, 5, 5, 5])
        XCTAssertEqual(sections.map { section in Int(section.top) }, [0, 678, 1356, 2034, 2712])
    }

    /// A hidden row shortens its band; a band with nothing drawn is left out.
    /// A blank row on a fixed layout keeps its height as an empty section.
    func testHiddenRowsShrinkBandsAndBlankRowsKeepTheirPlace() {
        var grid = fullGrid(42)
        for slot in 6...10 { grid[slot] = nil }      // row 2 hidden
        for slot in 23...42 { grid[slot] = nil }     // rows 5 and 6 hidden
        let shape = GridType.fortyTwo.rowShape
        let dynamic = ExportList.sections(
            groups: ExportList.groups(grid: grid, shape: shape),
            rowHeights: ExportList.rowHeights(shape: shape, width: 3366, spacing: 24),
            rowsPerSection: [2, 2, 2], hidesEmptyRows: true, spacing: 24)

        XCTAssertEqual(dynamic.map { section in section.lines.count }, [5, 12])
        XCTAssertEqual(dynamic.map { section in Int(section.height) }, [654, 1106])
        XCTAssertEqual(Int(dynamic[1].top), 678)

        var fixed = fullGrid(25)
        for slot in 6...10 { fixed[slot] = nil }
        let rows = ExportList.sections(
            groups: ExportList.groups(grid: fixed, shape: GridType.twentyFive.rowShape),
            rowHeights: Array(repeating: 654, count: 5),
            rowsPerSection: [1, 1, 1, 1, 1], hidesEmptyRows: false, spacing: 24)

        XCTAssertEqual(rows.count, 5)
        XCTAssertTrue(rows[1].lines.isEmpty)
        XCTAssertEqual(Int(rows[2].top), 1356, "the blank row still takes its height")
    }

    /// Groups that fit their rows start exactly where their rows start.
    func testGroupsThatFitTheirRowsStartLevelWithThem() {
        let rowTops: [CGFloat] = [0, 678, 1356, 2034, 2712]
        let heights: [CGFloat] = Array(repeating: 415, count: 5)

        let tops = ExportList.groupTops(preferred: rowTops, heights: heights, floor: 3366, gap: 24)

        XCTAssertEqual(tops, rowTops)
    }

    /// The 42 layout's ten-across rows are 315px for ten lines. The rule is
    /// that the list still ends at the grid's bottom, so the last groups pull
    /// up into the slack under the short groups above them. Rows one and two
    /// keep their alignment; the rest give a little each.
    func testTallGroupsPullUpIntoTheSlackAboveRatherThanPastTheGrid() {
        let rowTops: [CGFloat] = [0, 678, 1356, 1921, 2486, 2825]
        let heights: [CGFloat] = [267, 267, 323, 323, 547, 547]

        let tops = ExportList.groupTops(preferred: rowTops, heights: heights, floor: 3140, gap: 24)

        XCTAssertEqual(tops, [0, 678, 1328, 1675, 2022, 2593])
        XCTAssertEqual(tops.last! + heights.last!, 3140, "the list ends at the grid's bottom")
        for index in 1..<tops.count {
            XCTAssertGreaterThanOrEqual(tops[index], tops[index - 1] + heights[index - 1] + 24,
                                        "group \(index) overlaps the one above")
        }
    }

    /// More text than the grid is tall: the groups stay in order from the top
    /// and the end runs past the bottom, rather than the top going negative.
    func testAListTallerThanTheGridOverflowsFromTheTop() {
        let tops = ExportList.groupTops(preferred: [0, 500], heights: [800, 800], floor: 1000, gap: 24)

        XCTAssertEqual(tops, [0, 824])
    }

    /// Only the dynamic layout drops empty rows from the export. If a fixed
    /// layout ever starts hiding them, the sidebar has to know.
    func testOnlyTheDynamicLayoutHidesEmptyRows() {
        XCTAssertTrue(GridType.fortyTwo.hidesEmptyRows)
        for type in [GridType.twenty, .twentyWide, .twentyFive] {
            XCTAssertFalse(type.hidesEmptyRows, "\(type)")
        }
    }
}
