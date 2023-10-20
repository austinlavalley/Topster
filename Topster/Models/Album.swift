//
//  Album.swift
//  Topster
//
//  Created by Austin Lavalley on 10/2/23.
//

import Foundation

struct Album: Codable, Identifiable {
    
    let id = UUID()
    let name, artist: String
    let url: String
    let image: [Image]
    let streamable, mbid: String
    

    
    enum CodingKeys: String, CodingKey {
        case name, artist, url, image, streamable, mbid
    }
}


//extension Album: Codable {
//    // Implement init(from:) to decode additional properties
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        name = try container.decode(String.self, forKey: .name)
//        artist = try container.decode(String.self, forKey: .artist)
//        url = try container.decode(String.self, forKey: .url)
//        image = try container.decode([Image].self, forKey: .image)
//        streamable = try container.decode(String.self, forKey: .streamable)
//        mbid = try container.decode(String.self, forKey: .mbid)
//    }
//
//    // Implement encode(to:) if needed
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(name, forKey: .name)
//        try container.encode(artist, forKey: .artist)
//        try container.encode(url, forKey: .url)
//        try container.encode(image, forKey: .image)
//        try container.encode(streamable, forKey: .streamable)
//        try container.encode(mbid, forKey: .mbid)
//    }
//}
