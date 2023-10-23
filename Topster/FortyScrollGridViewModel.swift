//
//  FortyScrollGridViewModel.swift
//  Topster
//
//  Created by Austin Lavalley on 9/28/23.
//

import Foundation
import SwiftUI


class FortyScrollGridViewModel: ObservableObject {
    
    @Published var showSearchSheet = false
    
    // tracks the currently selected/most recently tapped grid. **CURRENTLY DOES NOT GET RESET BACK TO NIL ONCE DESELCTED**
    @Published var selectedGridID: Int?
    
    // state control for showing longpress remove dialog
    @Published var pressShowRemove = false
    
    
    // toggles album search sheet when grid is tapped
    func toggleSheet() {
        showSearchSheet.toggle()
    }
    
    // dismisses search sheet after a final action
    func hideSearchSheet() {
        showSearchSheet = false
    }
    
    
    
    
    
    // docs directory, core data, cloud???
     
    
    // main grid control, key is the grid space & value is an optional Album model
    @Published var FortyGridDict: [Int: Album?] = [
        1: nil, 2: nil, 3: nil, 4: nil, 5: nil, 6: nil, 7: nil, 8: nil, 9: nil, 10: nil, 11: nil, 12: nil, 13: nil, 14: nil, 15: nil, 16: nil, 17: nil, 18: nil, 19: nil, 20: nil, 21: nil, 22: nil, 23: nil, 24: nil, 25: nil, 26: nil, 27: nil, 28: nil, 29: nil, 30: nil, 31: nil, 32: nil, 33: nil, 34: nil, 35: nil, 36: nil, 37: nil, 38: nil, 39: nil, 40: nil
    ]
    
    // Create an AppStorage property for your dictionary with a default value
       @AppStorage("FortyGridDict", store: UserDefaults.standard) var storedFortyGridDict: Data?
    
    init() {
        // Load the saved data from AppStorage when initializing the view model
        if let savedData = storedFortyGridDict {
            if let decodedData = try? JSONDecoder().decode([Int: Album?].self, from: savedData) {
                FortyGridDict = decodedData
            }
        }
    }
    
    // Create a computed property to save and load the dictionary to/from AppStorage
    var savedFortyGridDict: [Int: Album?] {
        get {
            return FortyGridDict
        }
        set {
            FortyGridDict = newValue
            if let encodedData = try? JSONEncoder().encode(newValue) {
                storedFortyGridDict = encodedData
            }
        }
    }
    
    
    
    
    
    
    // assigns album to main grid dict at the currently selected grid id
    func addAlbumToGrid(album: Album, at index: Int) {
        FortyGridDict[index] = album
        savedFortyGridDict[index] = album
    }
    
    
    // resets the given key's value back to nil
    func removeAlbumFromGrid(at index: Int) {
        FortyGridDict.updateValue(nil, forKey: index)
    }
    
    
    // iterates through all keys and updates value to nil
    func clearGrid() {
        for key in FortyGridDict.keys {
            FortyGridDict.updateValue(nil, forKey: key)
        }
    }
    

    
}



