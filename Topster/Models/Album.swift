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
        imageURL(size: "extralarge") ?? imageURL(size: "large")
    }

    /// Smaller sizes of the same art, tried in order when `coverURL` fails.
    ///
    /// Last.fm's CDN makes each size on first request. When making the 300px
    /// one times out, it answers 404 and caches that 404 for up to ten years
    /// (`max-age=311040000`), while the 174px and 64px files for the same
    /// image load fine. Probed 18 Sep 2026: 74 of 555 covers from popular
    /// searches failed on first request, and one that 404ed at 300px was
    /// still 404ing at that edge fifteen minutes later. A soft cover beats a
    /// placeholder over art that exists.
    var coverFallbackURLs: [URL] {
        guard let primary = coverURL else { return [] }
        return [imageURL(size: "large"), imageURL(size: "medium")]
            .compactMap { url in url }
            .filter { url in url != primary }
    }

    private func imageURL(size: String) -> URL? {
        guard let text = image.first(where: { entry in entry.size == size })?.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return URL(string: text)
    }
}
