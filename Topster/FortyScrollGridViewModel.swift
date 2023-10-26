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
    
    
    
    @Published var savedGrids: [ [Int: Album?] ] = [
        [
            1: Optional(Topster.Album(name: "American Heartbreak", artist: "Zach Bryan", url: "https://www.last.fm/music/Zach+Bryan/American+Heartbreak", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("extralarge"))], streamable: "0", mbid: "")),
            2: Optional(Topster.Album(name: "Youth", artist: "Matisyahu", url: "https://www.last.fm/music/Matisyahu/Youth", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/62ee1cffdde64d1e9a3462c307f83bfd.png"), size: Optional("extralarge"))], streamable: "0", mbid: "b971671b-a135-4801-b65a-859815fb1813"))],
        [
            1: Optional(Topster.Album(name: "some rap songs", artist: "Earl Sweatshirt", url: "https://www.last.fm/music/Earl+Sweatshirt/some+rap+songs", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/b7b9b1e9d8007ddaeaa9ee8a8e45a4c3.png"), size: Optional("extralarge"))], streamable: "0", mbid: ""))
        ]
    ]
    
    // main grid control, key is the grid space & value is an optional Album model
    @Published var FortyGridDict: [Int: Album?] = [
        1: nil, 2: nil, 3: nil, 4: nil, 5: nil, 6: nil, 7: nil, 8: nil, 9: nil, 10: nil, 11: nil, 12: nil, 13: nil, 14: nil, 15: nil, 16: nil, 17: nil, 18: nil, 19: nil, 20: nil, 21: nil, 22: nil, 23: nil, 24: nil, 25: nil, 26: nil, 27: nil, 28: nil, 29: nil, 30: nil, 31: nil, 32: nil, 33: nil, 34: nil, 35: nil, 36: nil, 37: nil, 38: nil, 39: nil, 40: nil
    ]
    
    // Create an AppStorage property for your dictionary with a default value
    @AppStorage("FortyGridDict") var storedFortyGridDict: Data?
    @AppStorage("storedSavedGrids") var storedSavedGrids: Data?
    
    
    init() {
        // Load the saved data from AppStorage when initializing the view model
        if let savedData = storedFortyGridDict {
            if let decodedData = try? JSONDecoder().decode([Int: Album?].self, from: savedData) {
                FortyGridDict = decodedData
            }
        }
        if let storedGrids = storedSavedGrids {
            if let decodedData = try? JSONDecoder().decode([[Int: Album?]].self, from: storedGrids) {
                savedGrids = decodedData
            }
        }
    }
    
    // Create a computed property to save and load the dictionary to/from AppStorage
    var EditableFortyGridDict: [Int: Album?] {
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
    
    func addToSavedGrids(grid: [Int: Album?]) {
        savedGrids.append(grid)
    }
    
    
    
    
    
    // assigns album to main grid dict at the currently selected grid id
    func addAlbumToGrid(album: Album, at index: Int) {
        //        FortyGridDict[index] = album
        EditableFortyGridDict[index] = album
    }
    
    
    // resets the given key's value back to nil
    func removeAlbumFromGrid(at index: Int) {
        EditableFortyGridDict.updateValue(nil, forKey: index)
    }
    
    
    // iterates through all keys and updates value to nil
    func clearGrid() {
        for key in FortyGridDict.keys {
            EditableFortyGridDict.updateValue(nil, forKey: key)
        }
    }
    
    
    
}



