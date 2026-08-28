//
//  Networker.swift
//  Topster
//
//  Created by Austin Lavalley on 9/18/23.
//

import Foundation


/// What actually went wrong on a Last.fm call.
///
/// Every failure used to be flattened into `.success([])`, which made a rate
/// limit, a dropped connection and a genuinely empty search all look identical
/// to the UI. They are now distinguishable.
enum NetworkError: LocalizedError {
    case missingAPIKey
    case badURL
    case transport(Error)
    case http(status: Int)
    case api(code: Int, message: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Secrets.plist is missing or has no API_KEY."
        case .badURL:
            return "Couldn't build a valid request for that search."
        case .transport(let underlying):
            return underlying.localizedDescription
        case .http(let status):
            return "Last.fm returned HTTP \(status)."
        case .api(let code, let message):
            // 29 is Last.fm's rate limit code.
            return code == 29 ? "Too many searches at once. Give it a second." : message
        case .decoding:
            return "Couldn't read Last.fm's response."
        }
    }
}


/// Last.fm signals failure with `{"error": 10, "message": "..."}` rather than
/// the shape we asked for.
private struct LastFMErrorEnvelope: Decodable {
    let error: Int
    let message: String
}


class Networker {

    /// Read off disk once. This used to do a `Bundle.main.path` plus an
    /// `NSDictionary(contentsOfFile:)` on every single request.
    private static let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["API_KEY"] as? String
        else { return "" }
        return key
    }()

    /// `URLSession.shared` sets no request timeout, so a stalled call sat for the
    /// default 60 seconds before anyone heard about it.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()


    // MARK: - Calls

    /// Opens the encrypted connections to both search services without waiting
    /// on them. The search sheet fires this as it appears, so connection setup
    /// overlaps typing and the first search's lookup burst starts warm instead
    /// of spending its resolve budget on handshakes. Measured 27 Aug 2026:
    /// first call 0.29 s vs 0.10 s warm (Last.fm) and 0.72 s vs 0.38 s
    /// (Deezer) on wifi; the gap widens on LTE, where a cold burst was
    /// observed dropping its backfills. Responses are discarded.
    func warmConnections() {
        Task.detached {
            if let url = try? self.buildURL(method: "chart.gettopartists",
                                            parameters: ["limit": "1"]) {
                _ = try? await Self.session.data(from: url)
            }
        }
        Task.detached {
            if let url = URL(string: "https://api.deezer.com/infos") {
                _ = try? await Self.session.data(from: url)
            }
        }
    }

    func returnTopArtists() async throws -> [Artist] {
        let response: ArtistResponse = try await get(method: "chart.gettopartists")
        return response.artists.artist
    }

    func returnTopTracks() async throws -> [Track] {
        let response: TrackInfo = try await get(method: "chart.gettoptracks")
        return response.tracks.track
    }

    func searchArtists(query: String) async throws -> [Artist] {
        let response: SearchResults = try await get(method: "artist.search",
                                                    parameters: ["artist": query])
        return response.results.artistmatches?.artist ?? []
    }

    /// Asks for more than we intend to show, because callers filter out albums with
    /// no cover art and Last.fm returns a lot of those. A "kid a" search yields 17
    /// usable results out of 50, but 30 out of 100.
    func searchAlbums(query: String, limit: Int = 100) async throws -> [Album] {
        let response: SearchResults = try await get(method: "album.search",
                                                    parameters: ["album": query,
                                                                 "limit": String(limit)])
        return response.results.albummatches?.album ?? []
    }

    /// One album by exact artist and title, with its listener count. Resolves
    /// every head result's ranking number, and backfills popular albums that
    /// Deezer's list knows but Last.fm's search never returned, so everything
    /// shown is a Last.fm album with Last.fm cover art.
    func albumInfo(artist: String, album: String) async throws -> AlbumInfo {
        let response: AlbumInfoResponse = try await get(method: "album.getinfo",
                                                        parameters: ["artist": artist,
                                                                     "album": album,
                                                                     "autocorrect": "1"])
        let info = response.album
        return AlbumInfo(album: Album(name: info.name, artist: info.artist, url: info.url ?? "",
                                      image: info.image, streamable: "0", mbid: ""),
                         listeners: Int(info.listeners ?? "") ?? 0)
    }

    /// Deezer's ranking for the same query, used only to reorder Last.fm's results.
    /// See `SearchRanking`. Keyless and popularity-leaning; its limit matches
    /// `searchAlbums` so the two lists cover the same depth.
    func deezerRanking(query: String, limit: Int = 100) async throws -> [DeezerAlbum] {
        let url = try buildDeezerURL(query: query, limit: limit)
        let response: DeezerSearchResponse = try await fetch(from: url)
        return response.data
    }


    // MARK: - Plumbing

    private func get<T: Decodable>(method: String,
                                   parameters: [String: String] = [:]) async throws -> T {
        try await fetch(from: try buildURL(method: method, parameters: parameters))
    }

    private func fetch<T: Decodable>(from url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await Self.session.data(from: url)
        } catch {
            throw NetworkError.transport(error)
        }

        // Check for Last.fm's error shape before trying to decode what we asked for,
        // otherwise a 403 surfaces as an unhelpful decoding failure.
        if let envelope = try? JSONDecoder().decode(LastFMErrorEnvelope.self, from: data) {
            throw NetworkError.api(code: envelope.error, message: envelope.message)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NetworkError.http(status: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }

    /// Builds the request through `URLComponents` so every value is percent-encoded.
    ///
    /// The old code interpolated the raw search string straight into the URL, and
    /// `searchAlbums` replaced spaces with dashes, which is not encoding and quietly
    /// changed what was being searched for.
    // Not private so the tests can check encoding without going near the network.
    func buildURL(method: String, parameters: [String: String]) throws -> URL {
        guard !Self.apiKey.isEmpty else { throw NetworkError.missingAPIKey }

        var components = URLComponents(string: "https://ws.audioscrobbler.com/2.0/")

        var items = [URLQueryItem(name: "method", value: method)]
        items += parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        items += [
            URLQueryItem(name: "api_key", value: Self.apiKey),
            URLQueryItem(name: "format", value: "json")
        ]
        components?.queryItems = items

        // URLComponents leaves "+" alone because it is legal in a query, but Last.fm
        // reads a literal "+" as a space. Verified against the live API.
        if let encoded = components?.percentEncodedQuery {
            components?.percentEncodedQuery = encoded.replacingOccurrences(of: "+", with: "%2B")
        }

        guard let url = components?.url else { throw NetworkError.badURL }
        return url
    }

    /// No API key and no method parameter; Deezer's search endpoint is public.
    /// Gets the same `+` treatment as the Last.fm URLs so a query renders
    /// identically to both services.
    // Not private so the tests can check encoding without going near the network.
    func buildDeezerURL(query: String, limit: Int = 100) throws -> URL {
        var components = URLComponents(string: "https://api.deezer.com/search/album")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let encoded = components?.percentEncodedQuery {
            components?.percentEncodedQuery = encoded.replacingOccurrences(of: "+", with: "%2B")
        }

        guard let url = components?.url else { throw NetworkError.badURL }
        return url
    }
}
