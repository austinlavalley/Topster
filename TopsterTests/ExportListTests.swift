//
//  ExportListTests.swift
//  TopsterTests
//

import SwiftUI
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

    /// Rows inside a band stay separate so the list can gap between them. A
    /// blank row on a fixed layout keeps its section but adds no row group.
    func testSectionsKeepTheirRowsApart() {
        let shape = GridType.fortyTwo.rowShape
        let sections = ExportList.sections(
            groups: ExportList.groups(grid: fullGrid(42), shape: shape),
            rowHeights: ExportList.rowHeights(shape: shape, width: 3366, spacing: 24),
            rowsPerSection: GridType.fortyTwo.rowsPerListSection,
            hidesEmptyRows: true, spacing: 24)

        XCTAssertEqual(sections.map { section in section.rows.map(\.count) }, [[5, 5], [6, 6], [10, 10]])

        var fixed = fullGrid(25)
        for slot in 6...10 { fixed[slot] = nil }
        let rows = ExportList.sections(
            groups: ExportList.groups(grid: fixed, shape: GridType.twentyFive.rowShape),
            rowHeights: Array(repeating: 654, count: 5),
            rowsPerSection: [1, 1, 1, 1, 1], hidesEmptyRows: false, spacing: 24)

        XCTAssertEqual(rows[1].rows, [])
    }

    // MARK: Placement

    private func band(_ top: CGFloat, _ height: CGFloat) -> ExportListSection {
        ExportListSection(rows: [], top: top, height: height)
    }

    /// Sections that fit their bands, with a blank line to spare before the
    /// next band, start exactly where their bands start. This is the 5×5 as
    /// it has always shipped.
    func testSectionsThatFitStartLevelWithTheirBands() {
        let bands = [0, 678, 1356, 2034, 2712].map { top in band(top, 654) }

        let tops = ExportList.sectionTops(sections: bands, heights: Array(repeating: 430, count: 5),
                                          floor: 3366, minGap: 86)

        XCTAssertEqual(tops, [0, 678, 1356, 2034, 2712])
    }

    /// One section too tall for its band drops alignment for the whole list,
    /// which is spread from the grid's top to its bottom with equal gaps.
    /// The 42's shape: short first band, crowded last one.
    func testOneSectionThatDoesNotFitSpreadsTheWholeList() {
        let bands = [band(0, 1332), band(1356, 1106), band(2486, 654)]
        let heights: [CGFloat] = [700, 840, 1400]

        let tops = ExportList.sectionTops(sections: bands, heights: heights, floor: 3140, minGap: 70)

        XCTAssertEqual(tops, [0, 800, 1740])
        XCTAssertEqual(tops[2] + heights[2], 3140, "the list ends on the grid's bottom edge")
        XCTAssertEqual(tops[1] - (tops[0] + heights[0]), tops[2] - (tops[1] + heights[1]),
                       "the gaps are equal")
    }

    /// Fitting inside a band is not enough if it leaves less than a blank
    /// line before the next band: sections that nearly touch read as one.
    func testASectionThatCrowdsTheNextBandCountsAsNotFitting() {
        let bands = [band(0, 654), band(678, 654)]

        let tops = ExportList.sectionTops(sections: bands, heights: [650, 300], floor: 1332, minGap: 86)

        XCTAssertEqual(tops, [0, 1032])
    }

    /// Blank rows on a fixed layout have no lines. When the list spreads,
    /// they take no share of the gaps.
    func testEmptySectionsTakeNoPartInTheSpread() {
        let bands = [band(0, 654), band(678, 654), band(1356, 654)]

        let tops = ExportList.sectionTops(sections: bands, heights: [700, 0, 700], floor: 2010, minGap: 60)

        XCTAssertEqual(tops[0], 0)
        XCTAssertEqual(tops[2], 1310, "the last section ends on the floor")
    }

    /// Text taller than the grid, which only the size floor allows, runs
    /// past the bottom in order. It never overlaps and never starts above
    /// the top.
    func testTextTallerThanTheGridRunsLongRatherThanOverlapping() {
        let bands = [band(0, 400), band(424, 400)]

        let tops = ExportList.sectionTops(sections: bands, heights: [600, 600], floor: 824, minGap: 40)

        XCTAssertEqual(tops, [0, 600])
    }

    // MARK: Size

    /// Deterministic metrics, so the sizing rule is tested apart from fonts:
    /// 0.6em per character, 1.2em lines, greedy wrap by characters.
    private struct FakeTypesetter: ExportListTypesetter {
        func advance(size: CGFloat) -> CGFloat { size * 0.6 }
        func lineHeight(size: CGFloat) -> CGFloat { size * 1.2 }
        func height(of text: String, size: CGFloat, width: CGFloat) -> CGFloat {
            let perLine = max(1, Int(width / advance(size: size)))
            let lines = min(ExportListStyle.lineLimit, max(1, (text.count + perLine - 1) / perLine))
            return CGFloat(lines) * lineHeight(size: size)
        }
    }

    private func layoutSections(_ type: GridType, grid: [Int: Album?]) -> [ExportListSection] {
        ExportList.sections(
            groups: ExportList.groups(grid: grid, shape: type.rowShape),
            rowHeights: ExportList.rowHeights(shape: type.rowShape, width: ExportCanvas.width, spacing: 24),
            rowsPerSection: type.rowsPerListSection, hidesEmptyRows: type.hidesEmptyRows, spacing: 24)
    }

    private func floor(_ sections: [ExportListSection]) -> CGFloat {
        sections.last.map { section in section.top + section.height } ?? 0
    }

    /// The fixed layouts fit at the cap, so they keep 56pt.
    func testTheFixedLayoutsKeepTheCap() {
        for type in [GridType.twenty, .twentyWide, .twentyFive] {
            let sections = layoutSections(type, grid: fullGrid(type.slotCount))
            let size = ExportList.fontSize(sections: sections, floor: floor(sections), typesetter: FakeTypesetter())
            XCTAssertEqual(size, 56, "\(type)")
        }
    }

    /// The chosen size is the largest that fits: at it the list is inside
    /// the grid, half a point up it is not.
    func testTheSizeIsTheLargestThatFits() {
        let sections = layoutSections(.fortyTwo, grid: fullGrid(42))
        let typesetter = FakeTypesetter()
        let size = ExportList.fontSize(sections: sections, floor: 3140, typesetter: typesetter)

        XCTAssertLessThan(size, 56)
        XCTAssertLessThanOrEqual(ExportList.listHeight(sections, size: size, typesetter: typesetter), 3140)
        XCTAssertGreaterThan(ExportList.listHeight(sections, size: size + 0.5, typesetter: typesetter), 3140)
    }

    /// Row gaps are counted before the size is chosen, so adding them costs
    /// size and never pushes the list past the grid.
    func testRowGapsAreInTheHeight() {
        let typesetter = FakeTypesetter()
        let split = ExportListSection(rows: [[ExportListLine(number: 1, text: "a")],
                                             [ExportListLine(number: 2, text: "b")]], top: 0, height: 0)
        let joined = ExportListSection(rows: [[ExportListLine(number: 1, text: "a"),
                                               ExportListLine(number: 2, text: "b")]], top: 0, height: 0)

        let difference = ExportList.height(of: split, size: 40, digits: 1, typesetter: typesetter)
            - ExportList.height(of: joined, size: 40, digits: 1, typesetter: typesetter)

        XCTAssertEqual(difference, ExportListStyle.rowGap * 40, accuracy: 0.001)
    }

    /// The number column is sized for the widest number, and the title
    /// starts one character after it.
    func testTitlesStartAfterTheWidestNumber() {
        let typesetter = FakeTypesetter()

        XCTAssertEqual(ExportList.numberColumnWidth(digits: 2, size: 10, typesetter: typesetter), 18)
        XCTAssertEqual(ExportList.titleWidth(digits: 2, size: 10, typesetter: typesetter), 1600 - 18 - 6)
    }

    /// An empty list has no size to find and no height.
    func testAnEmptyListIsZeroHigh() {
        let sections = layoutSections(.fortyTwo, grid: [:])

        XCTAssertTrue(sections.isEmpty)
        XCTAssertEqual(ExportList.listHeight(sections, size: 56, typesetter: FakeTypesetter()), 0)
    }

    // MARK: Hostile names

    /// Names that have broken text layout elsewhere: no spaces to wrap at,
    /// glyphs far wider or taller than a Latin letter, right-to-left runs,
    /// stacked combining marks, control characters, markup, format strings.
    static let hostileNames: [(artist: String, name: String)] = [
        (String(repeating: "A", count: 400), String(repeating: "B", count: 400)),
        (String(repeating: "word ", count: 120), String(repeating: "longer words ", count: 80)),
        ("Line\nbreak", "Tab\tand\r\ncarriage\u{2028}separator"),
        ("", ""),
        ("   ", "\n\n\n"),
        ("", "Only an album"),
        ("Only an artist", ""),
        ("👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦🏳️‍🌈🇯🇵🇧🇷", String(repeating: "🎸🥁🎹", count: 30)),
        ("坂本龍一", String(repeating: "音楽図鑑戦場のメリークリスマス", count: 12)),
        ("فيروز", String(repeating: "أعطني الناي وغنّ ", count: 12)),
        ("\u{202E}reverse override", "mixed עברית and English ١٢٣ 123"),
        ("Z̷̢̧̛̖̗̘̙̜̝̞̟̠̤̥̦̩̪̫̬̭̮̯̰̱̲̳̹̺̻̼͇͈͉͍͎̀́̂̃̄̅̆̇̈̉̊̋̌̍̎̏̐̑̒̓̔̽̾̿̀́͂̓̈́͆͊͋͌̕̚ͅ͏͓͔͕͖͙͚͐͑͒͗͛ͣͤͥͦͧͨͩͪͫͬͭͮͯ͘͜͟͢͝͞͠͡a̶l̵g̴o", "ฏ๊๊๊๊๊ ཀྵྐྵྐྵྐྵ ᄀᄀᄀ"),
        ("﷽﷽﷽﷽", "𒐫𒐫𒐫𒐫𒐫𒐫𒐫𒐫"),
        ("**bold** [link](https://x.y) `code`", "%@ %d %n %s {0} \\(x) \\"),
        ("\u{0000}\u{0007}\u{FEFF}\u{200B}", "zero\u{200B}width\u{200B}joins\u{200D}everywhere"),
        (String(repeating: "W", count: 60), String(repeating: "m", count: 60)),
    ]

    private func hostileGrid(_ count: Int) -> [Int: Album?] {
        Dictionary(uniqueKeysWithValues: (1...count).map { key in
            let pick = Self.hostileNames[(key - 1) % Self.hostileNames.count]
            return (key, album(pick.artist, pick.name))
        })
    }

    /// Every caption is one line of text, whatever the name carried in.
    func testCaptionsCollapseWhitespaceAndDropAMissingSide() {
        XCTAssertEqual(album("Line\nbreak", "Tab\tand\r\nmore").exportCaption, "Line break – Tab and more")
        XCTAssertEqual(album("", "Only an album").exportCaption, "Only an album")
        XCTAssertEqual(album("Only an artist", "").exportCaption, "Only an artist")
        XCTAssertEqual(album("   ", "\n\n").exportCaption, "")
        XCTAssertEqual(album("  Guitar  Slim ", " Sufferin'  Mind").exportCaption, "Guitar Slim – Sufferin' Mind")
        XCTAssertEqual(album("\u{202E}reverse", "Album\u{2066}").exportCaption, "reverse – Album",
                       "a bidi override would run on past the dash")
        XCTAssertEqual(album("Bell\u{0007}\u{0000}", "Name").exportCaption, "Bell – Name")
        XCTAssertEqual(album("👨‍👩‍👧‍👦", "zero\u{200D}joiner").exportCaption, "👨‍👩‍👧‍👦 – zero\u{200D}joiner",
                       "joiners hold emoji together and stay")
        for pick in Self.hostileNames {
            let caption = album(pick.artist, pick.name).exportCaption
            XCTAssertFalse(caption.contains(where: \.isNewline), caption)
        }
    }

    /// With real SF Mono metrics, every layout's list fits its grid however
    /// hostile the names, and the 42 stays readable even when every title
    /// runs to two lines.
    func testHostileNamesStillFitEveryLayout() {
        let typesetter = SystemMonoTypesetter()
        for type in [GridType.fortyTwo, .twenty, .twentyWide, .twentyFive] {
            let sections = layoutSections(type, grid: hostileGrid(type.slotCount))
            let size = ExportList.fontSize(sections: sections, floor: floor(sections), typesetter: typesetter)

            XCTAssertLessThanOrEqual(ExportList.listHeight(sections, size: size, typesetter: typesetter),
                                     floor(sections), "\(type)")
            XCTAssertGreaterThanOrEqual(size, 24, "\(type) shrank to \(size)pt")
        }
    }

    /// The model the size is chosen from and the text SwiftUI draws have to
    /// agree, or the list overflows anyway. So this renders the real export,
    /// list on and list off, and requires the list to add width and never
    /// height. Checked that it can fail: pinning the size to 56 makes the 42's
    /// list image taller than its grid.
    @MainActor
    func testTheRenderedListNeverMakesTheExportTaller() throws {
        let cases: [(GridType, [Int: Album?])] = [
            (.fortyTwo, hostileGrid(42)),
            (.fortyTwo, fullGrid(42)),
            (.fortyTwo, hostileGrid(12)),
            (.twentyFive, hostileGrid(25)),
            (.twenty, hostileGrid(20)),
            (.twentyWide, hostileGrid(20)),
        ]

        for (type, grid) in cases {
            let suite = "ExportListTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }

            let vm = FortyScrollGridViewModel(defaults: defaults)
            vm.activeGridType = type
            vm.FortyGridDict = FortyScrollGridViewModel.padded(grid, to: type.slotCount)

            vm.exportLabels = .none
            let bare = try XCTUnwrap(ImageRenderer(content: ExportView().environmentObject(vm)).uiImage)
            vm.exportLabels = .list
            let listed = try XCTUnwrap(ImageRenderer(content: ExportView().environmentObject(vm)).uiImage)

            XCTAssertEqual(listed.size.height, bare.size.height, "\(type), \(grid.count) albums")
            XCTAssertGreaterThan(listed.size.width, bare.size.width, "\(type): the list did not draw")
        }
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
