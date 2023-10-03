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
    
    func toggleSheet(at gridID: Int?) {
        if gridID != nil { selectedGridID = gridID }
        showSearchSheet.toggle()
    }
    
    
    
    @Published var favoriteAlbums: [Album] = [] // Your data structure for favorite albums
    
//    func addAlbumToFavorites(album: Album) {
//        favoriteAlbums.append(album)
//    }
    
    func addAlbumToFavorites(album: Album) {
        var newAlbum = album
        newAlbum.gridPosition = selectedGridID
        favoriteAlbums.append(newAlbum)
    }
    
    
    
    
    
//    @Published var favoriteAlbums: [Album: Int] = [:]
//
//
//
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
