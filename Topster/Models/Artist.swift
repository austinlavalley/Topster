//
//  Artist.swift
//  Topster
//
//  Created by Austin Lavalley on 9/15/23.
//

import Foundation

struct ArtistInfo: Codable {
    let artists: Artists
}

struct Artists: Codable {
    let artist: [Artist]
}

struct Artist: Codable {
//    let name: String
//    let url: String
//    let playcount: String
    
        let name, listeners, mbid: String?
        let url: String?
        let streamable: String?
}
