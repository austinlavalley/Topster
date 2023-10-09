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
    
    
    
    
    
    
    @Published var FortyGridDict: [Int: Album?] = [1: nil, 2: nil, 3: nil, 4: nil, 5: nil]
    
    func addAlbumToFavorites(album: Album, at index: Int) {
        var newAlbum = album
        newAlbum.gridPosition = selectedGridID
        FortyGridDict[index] = newAlbum
    }
    
    
    

    
}



