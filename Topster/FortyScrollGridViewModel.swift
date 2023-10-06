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
    
//    let blankAlbum = Album(name: "Not Real", artist: <#T##String#>, url: <#T##String#>, image: <#T##[Image]#>, streamable: <#T##String#>, mbid: <#T##String#>)
    
    func toggleSheet(at gridID: Int?) {
        if gridID != nil { selectedGridID = gridID }
        showSearchSheet.toggle()
    }
    
    
    
    @Published var favoriteAlbums: [Album] = [] // Your data structure for favorite albums
    
    func addAlbumToFavorites(album: Album) {
        var newAlbum = album
        newAlbum.gridPosition = selectedGridID
        favoriteAlbums.append(newAlbum)
        FortyGridDict[1] = newAlbum
    }
    
    
    @Published var FortyGridDict: [Int: Album?] = [1: nil, 2: nil, 3: nil]
    

    
}



