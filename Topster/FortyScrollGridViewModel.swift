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
}

class FortyScrollGridViewModel: ObservableObject {
    @Published var tempExportDarkMode = UserDefaults.standard.bool(forKey: "appColorTheme")
    @Published var showSearchSheet = false
    @Published var showExportSheet = false
    @Published var selectedGridID: Int?
    @Published var pressShowRemove = false
    
    @Published var savedGrids: [GridWithType] = []
//    @Published var FortyGridDict: [Int: Album?] = [:]
    @Published var activeGridType = GridType.fortyTwo
    
    @Published var globalSpacing: CGFloat = 24
    
    
    @AppStorage("FortyGridDict") var storedFortyGridDict: Data?
    @AppStorage("storedSavedGrids") var storedSavedGrids: Data?
    @AppStorage("currentActiveGrid") var currentActiveGrid: Int? 
    
    
    init() {
        if let savedData = storedFortyGridDict,
           let decodedData = try? JSONDecoder().decode([Int: Album?].self, from: savedData) {
            FortyGridDict = decodedData
        }
        
        if let storedGrids = storedSavedGrids,
           let decodedData = try? JSONDecoder().decode([GridWithType].self, from: storedGrids) {
            savedGrids = decodedData
        }
        
        // Initialize FortyGridDict if it's empty
//        if FortyGridDict.isEmpty {
//            for i in 1...42 {
//                FortyGridDict[i] = nil
//            }
//        }
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
    
//    func addToSavedGrids(grid: [Int: Album?], type: GridType) {
//        let gridWithType = GridWithType(grid: grid, type: type)
//        EditableSavedGrids.append(gridWithType)
//        currentActiveGrid = savedGrids.count - 1
//    }
    
    func addToSavedGrids(name: String? = nil) {
        EditableSavedGrids.append(GridWithType(grid: FortyGridDict, type: activeGridType, name: name))
        currentActiveGrid = savedGrids.count - 1
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
    }
    
    func deleteAllSavedGrids() {
        EditableSavedGrids = []
        clearGrid()
        currentActiveGrid = nil
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
