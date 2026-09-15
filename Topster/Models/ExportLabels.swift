//
//  ExportLabels.swift
//  Topster
//

import Foundation

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
    var exportCaption: String {
        "\(artist) – \(name)"
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
    let lines: [ExportListLine]
    let top: CGFloat
    let height: CGFloat
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
    /// can hold no lines and still hold its place.
    static func sections(groups: [[ExportListLine]], rowHeights: [CGFloat],
                         rowsPerSection: [Int], hidesEmptyRows: Bool,
                         spacing: CGFloat) -> [ExportListSection] {
        var sections: [ExportListSection] = []
        var top: CGFloat = 0
        var rowIndex = 0

        for rowsInSection in rowsPerSection {
            var lines: [ExportListLine] = []
            var height: CGFloat = 0
            var drawnRows = 0

            for _ in 0..<rowsInSection where rowIndex < min(groups.count, rowHeights.count) {
                let group = groups[rowIndex]
                let rowHeight = rowHeights[rowIndex]
                rowIndex += 1
                if group.isEmpty && hidesEmptyRows { continue }
                lines += group
                height += (drawnRows > 0 ? spacing : 0) + rowHeight
                drawnRows += 1
            }

            if drawnRows == 0 { continue }
            sections.append(ExportListSection(lines: lines, top: top, height: height))
            top += height + spacing
        }

        return sections
    }

    /// Where each list section starts, given where its band starts, how tall
    /// the section is, and the bottom of the grid it must not cross.
    ///
    /// Every section wants the top of its band. When the sections fit their
    /// bands, that is what they get. When a section is taller than its band,
    /// which the dynamic layout's last band of twenty guarantees, the rule
    /// is that the list still ends at the grid's bottom: the last section is
    /// pinned there and each earlier one starts as low as it can without
    /// colliding, which spends the slack under the shorter sections above.
    /// Only if the whole list is taller than the grid does it run past the
    /// bottom, in order from the top.
    static func groupTops(preferred: [CGFloat], heights: [CGFloat],
                          floor: CGFloat, gap: CGFloat) -> [CGFloat] {
        let count = min(preferred.count, heights.count)
        guard count > 0 else { return [] }

        var tops = Array(repeating: CGFloat(0), count: count)
        var ceiling = floor
        for index in stride(from: count - 1, through: 0, by: -1) {
            tops[index] = min(preferred[index], ceiling - heights[index])
            ceiling = tops[index] - gap
        }

        if let first = tops.first, first < 0 {
            tops = tops.map { top in top - first }
        }
        return tops
    }
}
