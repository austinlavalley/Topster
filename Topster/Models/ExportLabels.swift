//
//  ExportLabels.swift
//  Topster
//

import UIKit

/// Where the artist and album names go on an exported grid, if anywhere.
///
/// Exclusive on purpose. The desktop tool treats captions and the list as two
/// independent toggles, but both at once says everything twice, and one
/// three-way control is easier to find than two switches.
enum ExportLabels: String, Codable, CaseIterable {
    case none
    case overlay
    case list
}

/// The fixed geometry every export layout is drawn into. The four layout
/// views in RenderView size their rows from this, and the sidebar has to use
/// the same numbers to land its groups on the rows.
enum ExportCanvas {
    /// Inner width of the grid, before the margin.
    static let width: CGFloat = 3366
    static let margin: CGFloat = 72
}

extension GridType {
    /// How many cells each row holds, top to bottom. The export views slice the
    /// grid dictionary by hand in exactly these runs, and the sidebar list
    /// groups its entries by them, so the two have to agree.
    var rowShape: [Int] {
        switch self {
        case .fortyTwo: return [5, 5, 6, 6, 10, 10]
        case .twenty: return [4, 4, 4, 4, 4]
        case .twentyWide: return [5, 5, 5, 5]
        case .twentyFive: return [5, 5, 5, 5, 5]
        }
    }

    /// Whether the export leaves out rows that hold no albums. Only the
    /// dynamic layout does (see `FortyTwoGridExportView`); the fixed grids
    /// draw every row with placeholders, so an empty row still takes height.
    var hidesEmptyRows: Bool {
        self == .fortyTwo
    }

    /// How many grid rows each sidebar section covers, top to bottom.
    ///
    /// The fixed layouts read as rows, so the list breaks at every row. The
    /// 42 reads as three bands of tile size, two rows each, and a list broken
    /// at every row put six groups against what looks like three; grouping
    /// by band is what matches the picture. Austin, 15 Sep 2026.
    var rowsPerListSection: [Int] {
        switch self {
        case .fortyTwo: return [2, 2, 2]
        case .twenty, .twentyWide, .twentyFive: return Array(repeating: 1, count: rowShape.count)
        }
    }
}

extension Album {
    /// "Artist – Album", the caption form the desktop tool uses.
    ///
    /// Whitespace runs, line breaks included, collapse to one space, because
    /// a name carrying its own newline would spend the list's two-line limit
    /// on nothing. Control characters and bidi overrides are dropped: an
    /// override in an artist's name otherwise runs on past the dash and
    /// draws the album title backwards. A missing side drops the dash rather
    /// than printing "Artist – ".
    var exportCaption: String {
        let parts = [artist, name]
            .map { part in
                String(String.UnicodeScalarView(part.unicodeScalars.filter { scalar in
                    !Self.captionStripped(scalar)
                }))
                .split(whereSeparator: \.isWhitespace)
                .joined(separator: " ")
            }
            .filter { part in !part.isEmpty }
        return parts.joined(separator: " – ")
    }

    /// Tabs and newlines are kept for the whitespace pass to turn into
    /// spaces; every other control character goes, with the bidi embedding,
    /// override and isolate controls. Joiners stay, since emoji need them.
    private static func captionStripped(_ scalar: Unicode.Scalar) -> Bool {
        if scalar.properties.isWhitespace { return false }
        if scalar.properties.generalCategory == .control { return true }
        return (0x202A...0x202E).contains(scalar.value) || (0x2066...0x2069).contains(scalar.value)
    }
}

/// One entry in the sidebar list.
struct ExportListLine: Equatable {
    let number: Int
    let text: String
}

/// One block of the sidebar list and where its band of rows sits in the
/// grid, measured through the rows the export draws.
struct ExportListSection: Equatable {
    /// One group per drawn row that holds albums, top to bottom. The sidebar
    /// puts a row gap between them.
    let rows: [[ExportListLine]]
    let top: CGFloat
    let height: CGFloat

    var lines: [ExportListLine] {
        rows.flatMap { row in row }
    }
}

/// Measures list entries the way the sidebar will draw them. The sizing rule
/// asks it for heights at candidate sizes before anything is rendered.
protocol ExportListTypesetter {
    /// Width of one character. The face is monospaced, so the number column
    /// is an exact multiple of it.
    func advance(size: CGFloat) -> CGFloat
    /// Height of one line of text.
    func lineHeight(size: CGFloat) -> CGFloat
    /// Height of `text` wrapped to `width`, at most two lines.
    func height(of text: String, size: CGFloat, width: CGFloat) -> CGFloat
}

/// SF Mono, measured through TextKit, which is what SwiftUI's `Text` lays
/// out with. Fallback glyphs (emoji, CJK, Arabic) are measured in the fonts
/// that actually draw them, so a line they make taller is counted taller.
struct SystemMonoTypesetter: ExportListTypesetter {
    private func font(_ size: CGFloat) -> UIFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    func advance(size: CGFloat) -> CGFloat {
        ("0" as NSString).size(withAttributes: [.font: font(size)]).width
    }

    func lineHeight(size: CGFloat) -> CGFloat {
        font(size).lineHeight
    }

    func height(of text: String, size: CGFloat, width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(string: text.isEmpty ? " " : text,
                                    attributes: [.font: font(size)])
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = ExportListStyle.lineLimit
        container.lineBreakMode = .byTruncatingTail
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        manager.ensureLayout(for: container)
        return ceil(manager.usedRect(for: container).height)
    }
}

/// The sidebar's type and spacing. Sizes in em scale with the chosen size.
enum ExportListStyle {
    /// The largest the list is ever set. What the fixed layouts have always
    /// used, and what they still get, because their lists fit at it.
    static let maxSize: CGFloat = 56
    /// Below this the list stops shrinking and is allowed to run long.
    /// Unreachable with two-line entries on the current layouts; a floor so
    /// the search always ends.
    static let minSize: CGFloat = 8
    static let sizeStep: CGFloat = 0.5
    static let lineLimit = 2
    /// Between titles.
    static let lineSpacing: CGFloat = 0.35
    /// Added between grid rows inside a section, on top of `lineSpacing`, so
    /// the list shows row breaks as well as band breaks.
    static let rowGap: CGFloat = 0.6
    /// The list column's width, numbers included.
    static let columnWidth: CGFloat = 1600
}

enum ExportList {
    /// The sidebar entries, one group per grid row, in row order. A row with
    /// no albums yields an empty group, so callers can still line the list
    /// up against rows the layout draws blank.
    ///
    /// Numbering runs over the albums actually placed, not over slots. The
    /// dynamic export hides rows with nothing in them, so slot numbers would
    /// jump at every hidden row and the list would count to 42 on a grid
    /// showing eleven covers.
    static func groups(grid: [Int: Album?], shape: [Int]) -> [[ExportListLine]] {
        var groups: [[ExportListLine]] = []
        var number = 0
        var slot = 1

        for rowLength in shape {
            var group: [ExportListLine] = []
            for _ in 0..<rowLength {
                if let album = grid[slot] ?? nil {
                    number += 1
                    group.append(ExportListLine(number: number, text: album.exportCaption))
                }
                slot += 1
            }
            groups.append(group)
        }

        return groups
    }

    /// The height of each row as the export draws it: square tiles filling
    /// the canvas width, with the grid's spacing between them.
    static func rowHeights(shape: [Int], width: CGFloat, spacing: CGFloat) -> [CGFloat] {
        shape.map { columns in
            (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        }
    }


    /// The row groups merged into the sections the sidebar draws, each with
    /// the top and height of its band of rows as the export lays them out.
    ///
    /// Rows the layout hides contribute nothing and take no height, so a
    /// band with one hidden row is shorter and a band with none drawn is
    /// left out. Rows the layout draws blank keep their height, so a section
    /// can hold no lines and still hold its place. A blank row adds no group,
    /// so it leaves no row gap in the list.
    static func sections(groups: [[ExportListLine]], rowHeights: [CGFloat],
                         rowsPerSection: [Int], hidesEmptyRows: Bool,
                         spacing: CGFloat) -> [ExportListSection] {
        var sections: [ExportListSection] = []
        var top: CGFloat = 0
        var rowIndex = 0

        for rowsInSection in rowsPerSection {
            var rows: [[ExportListLine]] = []
            var height: CGFloat = 0
            var drawnRows = 0

            for _ in 0..<rowsInSection where rowIndex < min(groups.count, rowHeights.count) {
                let group = groups[rowIndex]
                let rowHeight = rowHeights[rowIndex]
                rowIndex += 1
                if group.isEmpty && hidesEmptyRows { continue }
                if !group.isEmpty { rows.append(group) }
                height += (drawnRows > 0 ? spacing : 0) + rowHeight
                drawnRows += 1
            }

            if drawnRows == 0 { continue }
            sections.append(ExportListSection(rows: rows, top: top, height: height))
            top += height + spacing
        }

        return sections
    }

    /// How many characters the widest number takes, so "9." and "42." end in
    /// the same column.
    static func numberDigits(_ sections: [ExportListSection]) -> Int {
        String(sections.last(where: { section in !section.lines.isEmpty })?.lines.last?.number ?? 0).count
    }

    /// The number column: the digits and the full stop, right-aligned.
    static func numberColumnWidth(digits: Int, size: CGFloat,
                                  typesetter: ExportListTypesetter) -> CGFloat {
        typesetter.advance(size: size) * CGFloat(digits + 1)
    }

    /// What is left of the column for titles once the numbers and the one
    /// space after them are taken. A wrapped title continues in here, under
    /// the title rather than under its number.
    static func titleWidth(digits: Int, size: CGFloat, typesetter: ExportListTypesetter) -> CGFloat {
        ExportListStyle.columnWidth
            - numberColumnWidth(digits: digits, size: size, typesetter: typesetter)
            - typesetter.advance(size: size)
    }

    /// The least space between two sections: one blank line.
    static func sectionGap(size: CGFloat, typesetter: ExportListTypesetter) -> CGFloat {
        typesetter.lineHeight(size: size) + ExportListStyle.lineSpacing * size
    }

    /// A section's height at `size`: its entries, the spacing between them,
    /// and the wider gap wherever a grid row ends.
    static func height(of section: ExportListSection, size: CGFloat, digits: Int,
                       typesetter: ExportListTypesetter) -> CGFloat {
        let rows = section.rows.filter { row in !row.isEmpty }
        guard !rows.isEmpty else { return 0 }

        let width = titleWidth(digits: digits, size: size, typesetter: typesetter)
        let text = rows.joined().reduce(CGFloat(0)) { total, line in
            total + max(typesetter.height(of: line.text, size: size, width: width),
                        typesetter.lineHeight(size: size))
        }
        let entries = rows.reduce(0) { count, row in count + row.count }
        let spacing = CGFloat(entries - 1) * ExportListStyle.lineSpacing * size
        let rowGaps = CGFloat(rows.count - 1) * ExportListStyle.rowGap * size
        return text + spacing + rowGaps
    }

    /// The whole list at its tightest: every section, one blank line between.
    static func listHeight(_ sections: [ExportListSection], size: CGFloat,
                           typesetter: ExportListTypesetter) -> CGFloat {
        let digits = numberDigits(sections)
        let heights = sections
            .map { section in height(of: section, size: size, digits: digits, typesetter: typesetter) }
            .filter { height in height > 0 }
        guard !heights.isEmpty else { return 0 }
        return heights.reduce(0, +)
            + CGFloat(heights.count - 1) * sectionGap(size: size, typesetter: typesetter)
    }

    /// One size for the whole list: the largest, up to `maxSize`, at which
    /// the list fits the grid's height with a blank line between sections.
    ///
    /// One size per export, never one per band. Austin, 23 Sep 2026: "I
    /// definitely don't want to have variable font size on the same export."
    /// The fixed layouts fit at the cap and come out as they always have;
    /// the 42 lands in the mid 40s, where 32pt used to leave a hole under
    /// its first band.
    ///
    /// Heights only grow with size, so this is a binary search over the
    /// half-point steps rather than a walk down from the top, which would
    /// lay out every entry up to ninety times per render.
    static func fontSize(sections: [ExportListSection], floor: CGFloat,
                         typesetter: ExportListTypesetter) -> CGFloat {
        let style = ExportListStyle.self
        let steps = Int(((style.maxSize - style.minSize) / style.sizeStep).rounded())
        func size(_ step: Int) -> CGFloat { style.minSize + CGFloat(step) * style.sizeStep }
        func fits(_ step: Int) -> Bool {
            listHeight(sections, size: size(step), typesetter: typesetter) <= floor
        }

        guard fits(0) else { return style.minSize }
        var low = 0, high = steps
        while low < high {
            let middle = (low + high + 1) / 2
            if fits(middle) { low = middle } else { high = middle - 1 }
        }
        return size(low)
    }

    /// Where each section starts, from the rendered section heights.
    ///
    /// When every section fits its band with a blank line to spare before
    /// the next band, each starts level with its band. When any does not,
    /// alignment is dropped for the whole list, not patched per section:
    /// the sections are spread evenly from the grid's top to its bottom.
    /// Pinning only the overflowing ones is what used to leave a hole under
    /// the 42's first band and crush its last one against the bottom edge.
    ///
    /// Empty sections (blank rows on the fixed layouts) take part in the
    /// alignment check but not in the spread, so they add no extra gap.
    static func sectionTops(sections: [ExportListSection], heights: [CGFloat],
                            floor: CGFloat, minGap: CGFloat) -> [CGFloat] {
        let count = min(sections.count, heights.count)
        guard count > 0 else { return [] }

        let fitsBands = (0..<count).allSatisfy { index in
            let room = index + 1 < count
                ? sections[index + 1].top - sections[index].top - minGap
                : sections[index].height
            return heights[index] <= room
        }
        if fitsBands {
            return sections.prefix(count).map(\.top)
        }

        let drawn = (0..<count).filter { index in heights[index] > 0 }
        var tops = sections.prefix(count).map(\.top)
        guard drawn.count > 1 else {
            for index in drawn { tops[index] = 0 }
            return tops
        }

        let text = drawn.reduce(CGFloat(0)) { total, index in total + heights[index] }
        // Never below zero. If the text alone is taller than the grid, which
        // only the size floor allows, the list runs past the bottom rather
        // than drawing sections over each other.
        let gap = max(0, (floor - text) / CGFloat(drawn.count - 1))
        var y: CGFloat = 0
        for index in drawn {
            tops[index] = y
            y += heights[index] + gap
        }
        return tops
    }
}
