//
//  Track.swift
//  Topster
//
//  Created by Austin Lavalley on 9/15/23.
//

import Foundation

struct TrackInfo: Codable {
    let tracks: Tracks
}

struct Tracks: Codable {
    let track: [Track]
}

struct Track: Codable {
    let name: String
    let duration: String
    let artist: Artist
    // Add more properties as needed

    struct Artist: Codable {
        let name: String
        let url: String
    }
}
