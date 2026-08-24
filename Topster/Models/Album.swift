//
//  Album.swift
//  Topster
//
//  Created by Austin Lavalley on 10/2/23.
//

import Foundation

struct Album: Codable, Identifiable, Equatable {
    
    let id = UUID()
    let name, artist: String
    let url: String
    let image: [AlbumImage]
    let streamable, mbid: String
    

    
    enum CodingKeys: String, CodingKey {
        case name, artist, url, image, streamable, mbid
    }
    
    
    
    static func == (lhs: Album, rhs: Album) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.artist == rhs.artist
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


extension Album {

    /// The cover art URL, or nil when Last.fm has no art on file for this album.
    ///
    /// Last.fm returns an empty string rather than omitting the field, and it does
    /// so for a large share of any result set. `URL(string: "")` is nil, and both
    /// `AsyncImage` and `InternetImage` sit on a spinner forever when handed nil,
    /// which is what users were reporting as albums taking minutes to load.
    /// Callers should treat nil here as "no cover exists" and draw a placeholder.
    var coverURL: URL? {
        // extralarge is 300px against large's 174px. Grid cells render around 354
        // physical pixels on a current iPhone, so large was being upscaled roughly
        // 2x and looked soft. It costs 2.6x the bytes for no measurable latency
        // difference, because the wait is origin round-trip time rather than
        // transfer time. Falls back to large, though across 400 albums checked the
        // two are always present or absent together.
        for size in ["extralarge", "large"] {
            if let text = image.first(where: { entry in entry.size == size })?.text,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return URL(string: text)
            }
        }

        return nil
    }
}
