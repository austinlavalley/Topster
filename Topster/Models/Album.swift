//
//  Album.swift
//  Topster
//
//  Created by Austin Lavalley on 10/2/23.
//

import Foundation

struct Album: Codable {
//    static func == (lhs: Album, rhs: Album) -> Bool {
//        lhs.id == rhs.id
//    }
//    var id = UUID()
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(name)
//        hasher.combine(artist)
//    }

//    let index: Int // Index of the album in the grid
    
    let name, artist: String
    let url: String
    let image: [Image]
    let streamable, mbid: String
}
