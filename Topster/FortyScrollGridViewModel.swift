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
    
    func toggleSheet() {
        showSearchSheet.toggle()
    }
    
    
    
    @Published var favoriteAlbums: [Album] = [] // Your data structure for favorite albums

    
//    func addAlbumToFavorites(_ album: Album, at index: Int) {
//        // Check if an album with the same index already exists, and if so, update it
//        if let existingIndex = favoriteAlbums.firstIndex(where: { $0.index == index }) {
//            favoriteAlbums[existingIndex] = album
//        } else {
//            // If no album with the same index exists, append the new album
//            favoriteAlbums.append(album)
//        }
//    }
    
    
}
