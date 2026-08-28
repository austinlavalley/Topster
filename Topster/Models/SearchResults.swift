//
//  SearchResults.swift
//  Topster
//
//  Created by Austin Lavalley on 9/20/23.
//

import Foundation


// MARK: - SearchResults
struct SearchResults: Codable {
    let results: Results
}

// MARK: - Results
struct Results: Codable {
    let opensearchQuery: OpensearchQuery?
    let opensearchTotalResults, opensearchStartIndex, opensearchItemsPerPage: String?
    let artistmatches: Artistmatches?
    let albummatches: Albummatches?
    
}

// MARK: - Artistmatches
struct Artistmatches: Codable {
    let artist: [Artist]
}

// MARK: - Albummatches
struct Albummatches: Codable {
    let album: [Album]
}

// MARK: - AlbumInfoResponse
/// `album.getInfo`, used to backfill an album Last.fm's search never returned.
/// Unlike the search shape, `artist` here is a plain string and there is no
/// `streamable` or reliable `mbid`, so this cannot decode straight into `Album`.
struct AlbumInfoResponse: Decodable {
    struct Info: Decodable {
        let name: String
        let artist: String
        let url: String?
        let image: [AlbumImage]
        /// A number in a string, per Last.fm convention. This is the ranking
        /// axis for search results: global, popularity-shaped, and free with
        /// the same call that fetches the album.
        let listeners: String?
    }

    let album: Info
}

/// What a getInfo lookup resolves to: the album plus the popularity number the
/// head of the results is sorted by.
struct AlbumInfo {
    let album: Album
    let listeners: Int
}









// MARK: - Image
struct AlbumImage: Codable {
    let text: String?
    let size: String?
    
    enum CodingKeys: String, CodingKey {
        case text = "#text"
        case size = "size"
    }
}

// MARK: - OpensearchQuery
struct OpensearchQuery: Codable {
    let text, role, searchTerms, startPage: String?
}
