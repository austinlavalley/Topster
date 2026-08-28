//
//  DeezerSearch.swift
//  Topster
//

import Foundation


/// The slice of Deezer's `search/album` response the ranking hint needs.
///
/// Deezer is never a source of results. Its ordering is popularity-leaning where
/// Last.fm's is exact-title-match, so its list is used only to reorder the albums
/// Last.fm already returned. Nothing from here reaches the UI or disk, which is
/// why these are Decodable only and deliberately not `Album`.
struct DeezerSearchResponse: Decodable {
    let data: [DeezerAlbum]
}

struct DeezerAlbum: Decodable {
    let title: String
    let artist: DeezerArtist
}

struct DeezerArtist: Decodable {
    let name: String
}
