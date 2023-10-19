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
    @Published var selectedGridID: Int?
    
    
    func toggleSheet() {
        showSearchSheet.toggle()
    }
    
    func hideSearchSheet() {
        showSearchSheet = false
//        selectedGridID = nil
    }
    
    
    
    
    
    
    @Published var FortyGridDict: [Int: Album?] = [
        1: nil, 2: nil, 3: nil, 4: nil, 5: nil, 6: nil, 7: nil, 8: nil, 9: nil, 10: nil, 11: nil, 12: nil, 13: nil, 14: nil, 15: nil, 16: nil, 17: nil, 18: nil, 19: nil, 20: nil, 21: nil, 22: nil, 23: nil, 24: nil, 25: nil, 26: nil, 27: nil, 28: nil, 29: nil, 30: nil, 31: nil, 32: nil, 33: nil, 34: nil, 35: nil, 36: nil, 37: nil, 38: nil, 39: nil, 40: nil
    ]
    
    func addAlbumToFavorites(album: Album, at index: Int) {
        var newAlbum = album
        newAlbum.gridPosition = selectedGridID
        FortyGridDict[index] = newAlbum
    }
    
    func removeAlbumFromGrid(at index: Int) {
//        FortyGridDict.removeValue(forKey: index)
        FortyGridDict.updateValue(nil, forKey: index)
    }
    
    
    func clearGrid() {
        for key in FortyGridDict.keys {
            FortyGridDict.updateValue(nil, forKey: key)
        }
    }
    

    
}



