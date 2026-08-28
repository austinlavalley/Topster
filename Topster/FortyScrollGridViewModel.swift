//
//  FortyScrollGridViewModel.swift
//  Topster
//
//  Created by Austin Lavalley on 9/28/23.
//

import Foundation
import SwiftUI


//class FortyScrollGridViewModel: ObservableObject {
//    
//    @Published var tempExportDarkMode = UserDefaults.standard.bool(forKey: "appColorTheme")
//    
//    @Published var showSearchSheet = false
//    
//    @Published var showExportSheet = false
//    
//    // tracks the currently selected/most recently tapped grid. **CURRENTLY DOES NOT GET RESET BACK TO NIL ONCE DESELCTED**
//    @Published var selectedGridID: Int?
//    
//    // state control for showing longpress remove dialog
//    @Published var pressShowRemove = false
//    
//    
//    // toggles album search sheet when grid is tapped
//    func toggleSheet() {
//        showSearchSheet.toggle()
//    }
//    
//    // dismisses search sheet after a final action
//    func hideSearchSheet() {
//        showSearchSheet = false
//    }
//    
//    
//    // if wanting to add grid names, will need to add it in this var
//    // i guess would be an array of arrays, in which each has the grid name, as well as the dict
//    //
//    //  [    [ gridName, [Int: Album?] ]     ]
//    //
//    
//    @Published var savedGrids: [ [Int: Album?] ] = []
//    
//    // main grid control, key is the grid space & value is an optional Album model
//    @Published var FortyGridDict: [Int: Album?] = [
//        1: nil, 2: nil, 3: nil, 4: nil, 5: nil, 6: nil, 7: nil, 8: nil, 9: nil, 10: nil, 11: nil, 12: nil, 13: nil, 14: nil, 15: nil, 16: nil, 17: nil, 18: nil, 19: nil, 20: nil, 21: nil, 22: nil, 23: nil, 24: nil, 25: nil, 26: nil, 27: nil, 28: nil, 29: nil, 30: nil, 31: nil, 32: nil, 33: nil, 34: nil, 35: nil, 36: nil, 37: nil, 38: nil, 39: nil, 40: nil
//    ]
//
//    
//    
//    enum gridType {
//        case forty
//        case twenty
//        case twentyWide
//        case twentyFive
//    }
//    
//    @Published var activeGridType = gridType.forty
//    
//    
//    // Create an AppStorage property for your dictionary with a default value
//    @AppStorage("FortyGridDict") var storedFortyGridDict: Data?
//    @AppStorage("storedSavedGrids") var storedSavedGrids: Data?
//    
//    @AppStorage("currentActiveGrid") var currentActiveGrid: Int?
//    
//    
//    init() {
//        // Load the saved data from AppStorage when initializing the view model
//        if let savedData = storedFortyGridDict {
//            if let decodedData = try? JSONDecoder().decode([Int: Album?].self, from: savedData) {
//                FortyGridDict = decodedData
//            }
//        }
//        if let storedGrids = storedSavedGrids {
//            if let decodedData = try? JSONDecoder().decode([[Int: Album?]].self, from: storedGrids) {
//                savedGrids = decodedData
//            }
//        }
//    }
//    
//    // Create a computed property to save and load the dictionary to/from AppStorage
//    var EditableFortyGridDict: [Int: Album?] {
//        get {
//            return FortyGridDict
//        }
//        set {
//            FortyGridDict = newValue
//            if let encodedData = try? JSONEncoder().encode(newValue) {
//                storedFortyGridDict = encodedData
//            }
//        }
//    }
//    
//    var EditableSavedGrids: [ [Int: Album?] ] {
//        get {
//            return savedGrids
//        }
//        set {
//            savedGrids = newValue
//            if let encodedData = try? JSONEncoder().encode(newValue) {
//                storedSavedGrids = encodedData
//            }
//        }
//    }
//    
//    func addToSavedGrids(grid: [Int: Album?]) {
//        EditableSavedGrids.append(grid)
//        currentActiveGrid = savedGrids.count - 1
//    }
//    
//    func removeFromSavedGrids(at index: Int) {
//        EditableSavedGrids.remove(at: index)
//    }
//    
//    func deleteAllSavedGrids() {
//        EditableSavedGrids = [ ]
//    }
//    
//    
//    
//    
//    // assigns album to main grid dict at the currently selected grid id
//    func addAlbumToGrid(album: Album, at index: Int) {
//        EditableFortyGridDict[index] = album
//        currentActiveGrid = nil
//    }
//    
//    
//    // resets the given key's value back to nil
//    func removeAlbumFromGrid(at index: Int) {
//        EditableFortyGridDict.updateValue(nil, forKey: index)
//        currentActiveGrid = nil
//    }
//    
//    
//    
//    
//    
//    
//    // iterates through all keys and updates value to nil
//    func clearGrid() {
//        for key in FortyGridDict.keys {
//            EditableFortyGridDict.updateValue(nil, forKey: key)
//        }
//    }
//    
//    
//    
//    
//
//    
//}



import Foundation
import SwiftUI

struct GridWithType: Codable {
    var grid: [Int: Album?]
    var type: GridType
    
    var name: String?
}

enum GridType: String, Codable {
    case fortyTwo
    case twenty
    case twentyWide
    case twentyFive

    /// How many cells this layout owns. The grid views slice the dictionary by
    /// key, so the dictionary must actually hold this many keys or rows simply
    /// vanish from the screen.
    var slotCount: Int {
        switch self {
        case .fortyTwo: return 42
        case .twenty, .twentyWide: return 20
        case .twentyFive: return 25
        }
    }
}

class FortyScrollGridViewModel: ObservableObject {
    @Published var tempExportDarkMode = UserDefaults.standard.bool(forKey: "appColorTheme")
    @Published var showSearchSheet = false
    @Published var showExportSheet = false
    @Published var selectedGridID: Int?
    @Published var pressShowRemove = false

    @Published var savedGrids: [GridWithType] = []

    /// Persisted on change and restored in init. The grid's *contents* always
    /// survived relaunch but this did not, so an unsaved twentyFive grid came
    /// back displayed as fortyTwo. (didSet does not fire during init, so
    /// restoring the value does not rewrite it.)
    @Published var activeGridType = GridType.fortyTwo {
        didSet { defaults.set(activeGridType.rawValue, forKey: "activeGridType") }
    }

    private let defaults: UserDefaults

    @Published var globalSpacing: CGFloat = 24
    
    
    @AppStorage("FortyGridDict") var storedFortyGridDict: Data?
    @AppStorage("storedSavedGrids") var storedSavedGrids: Data?
    @AppStorage("currentActiveGrid") var currentActiveGrid: Int? 
    
    
    /// Restores any slot keys a stored grid is missing.
    ///
    /// The grid views render cells by slicing the dictionary, so a dictionary
    /// with fewer keys than its layout silently deletes rows from the screen.
    /// A 20-key dict labelled fortyTwo shipped exactly that way on 27 Aug 2026:
    /// stale test state was saved once and then propagated into every grid
    /// saved after it, with no way back from inside the app. Padding on load
    /// makes the damage heal instead of spread.
    static func padded(_ grid: [Int: Album?], to slotCount: Int) -> [Int: Album?] {
        var grid = grid
        // updateValue, not subscript assignment: through the subscript a nil
        // means "remove the key", which is the opposite of inserting an empty
        // slot.
        for key in 1...slotCount where grid[key] == nil {
            grid.updateValue(nil, forKey: key)
        }
        return grid
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Restore the layout before the grid, because padding sizes itself by
        // the layout.
        if let raw = defaults.string(forKey: "activeGridType"),
           let restored = GridType(rawValue: raw) {
            activeGridType = restored
        }

        if let savedData = storedFortyGridDict,
           let decodedData = try? JSONDecoder().decode([Int: Album?].self, from: savedData) {
            FortyGridDict = Self.padded(decodedData, to: activeGridType.slotCount)
        }

        if let storedGrids = storedSavedGrids,
           let decodedData = try? JSONDecoder().decode([GridWithType].self, from: storedGrids) {
            savedGrids = decodedData.map { saved in
                GridWithType(grid: Self.padded(saved.grid, to: saved.type.slotCount),
                             type: saved.type,
                             name: saved.name)
            }
        }

        // currentActiveGrid is an index into savedGrids, and the two are stored
        // separately. If the grids fail to decode, or the two ever fall out of step,
        // the index is left pointing past the end of an array the view subscripts
        // directly, which traps on launch with no way back short of deleting the app.
        if let active = currentActiveGrid, !savedGrids.indices.contains(active) {
            currentActiveGrid = nil
        }
    }

    /// The saved grid currently open, or nil.
    ///
    /// Use this rather than subscripting savedGrids with currentActiveGrid. The
    /// index survives independently of the array, so a bare subscript is a crash
    /// waiting for the two to disagree.
    var activeGrid: GridWithType? {
        guard let active = currentActiveGrid,
              savedGrids.indices.contains(active)
        else { return nil }

        return savedGrids[active]
    }
    
        // main grid control, key is the grid space & value is an optional Album model
        @Published var FortyGridDict: [Int: Album?] = [
            1: nil, 2: nil, 3: nil, 4: nil, 5: nil, 6: nil, 7: nil, 8: nil, 9: nil, 10: nil, 11: nil, 12: nil, 13: nil, 14: nil, 15: nil, 16: nil, 17: nil, 18: nil, 19: nil, 20: nil, 21: nil, 22: nil, 23: nil, 24: nil, 25: nil, 26: nil, 27: nil, 28: nil, 29: nil, 30: nil, 31: nil, 32: nil, 33: nil, 34: nil, 35: nil, 36: nil, 37: nil, 38: nil, 39: nil, 40: nil, 41: nil, 42: nil
        ]

    
    var EditableFortyGridDict: [Int: Album?] {
        get { FortyGridDict }
        set {
            FortyGridDict = newValue
            if let encodedData = try? JSONEncoder().encode(newValue) {
                storedFortyGridDict = encodedData
            }
        }
    }
    
    var EditableSavedGrids: [GridWithType] {
        get { savedGrids }
        set {
            savedGrids = newValue
            if let encodedData = try? JSONEncoder().encode(newValue) {
                storedSavedGrids = encodedData
            }
        }
    }
    
    
    func addToSavedGrids(name: String? = nil) {
        EditableSavedGrids.append(GridWithType(grid: FortyGridDict, type: activeGridType, name: name))
        currentActiveGrid = savedGrids.count - 1

        // Keep a local copy of the art so this grid survives Last.fm dropping a URL,
        // and renders offline. Writes what is already cached, so no new downloads.
        CoverArchive.archive(FortyGridDict.values.compactMap { entry in entry })
    }
    
    
    func updateName(name: String? = nil) {
        guard currentActiveGrid != nil else {
            addToSavedGrids(name: name)
            return
        }
        
        
        EditableSavedGrids[currentActiveGrid!].name = name
    }
    
    
    func removeFromSavedGrids(at index: Int) {
        EditableSavedGrids.remove(at: index)
        pruneCoverArchive()
    }
    
    func deleteAllSavedGrids() {
        EditableSavedGrids = []
        clearGrid()
        currentActiveGrid = nil
        pruneCoverArchive()
    }

    /// Drops archived covers no remaining saved grid refers to.
    ///
    /// Passes the full keep set rather than a delete list, so a cover shared between
    /// two grids survives when one of them goes.
    private func pruneCoverArchive() {
        let keep = savedGrids
            .flatMap { saved in saved.grid.values }
            .compactMap { entry in entry?.coverURL?.absoluteString }

        CoverArchive.prune(keeping: Set(keep))
    }
    
    func addAlbumToGrid(album: Album, at index: Int) {
        EditableFortyGridDict[index] = album
        currentActiveGrid = nil
    }
    
    func removeAlbumFromGrid(at index: Int) {
        EditableFortyGridDict.updateValue(nil, forKey: index)
        currentActiveGrid = nil
    }
    
    func clearGrid() {
        for key in FortyGridDict.keys {
            EditableFortyGridDict.updateValue(nil, forKey: key)
        }
    }
    
    func toggleSheet() {
        showSearchSheet.toggle()
    }
    
    func hideSearchSheet() {
        showSearchSheet = false
    }
}
