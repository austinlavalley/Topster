//
//  ResponseDecodingTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// Shapes taken from real Last.fm responses. Decoding failures used to surface as
/// an empty result list, which looked identical to a search that found nothing.
final class ResponseDecodingTests: XCTestCase {

    func testAlbumSearchDecodes() throws {
        let json = """
        {"results":{"opensearch:Query":{"#text":"","role":"request","searchTerms":"kid a","startPage":"1"},
        "opensearch:totalResults":"9000","opensearch:startIndex":"0","opensearch:itemsPerPage":"50",
        "albummatches":{"album":[
          {"name":"Kid A","artist":"Radiohead","url":"https://www.last.fm/music/Radiohead/Kid+A",
           "image":[{"#text":"https://example.com/34.png","size":"small"},
                    {"#text":"https://example.com/64.png","size":"medium"},
                    {"#text":"https://example.com/174.png","size":"large"},
                    {"#text":"https://example.com/300.png","size":"extralarge"}],
           "streamable":"0","mbid":"080ad926-7a4e-4399-b7df-0cc1b6ef841c"}]}}}
        """
        let decoded = try JSONDecoder().decode(SearchResults.self, from: Data(json.utf8))
        let albums = try XCTUnwrap(decoded.results.albummatches?.album)

        XCTAssertEqual(albums.count, 1)
        XCTAssertEqual(albums.first?.name, "Kid A")
        XCTAssertEqual(albums.first?.coverURL?.absoluteString, "https://example.com/300.png")
    }

    /// A third of real results look like this.
    func testAlbumWithNoArtDecodesAndResolvesToNil() throws {
        let json = """
        {"results":{"albummatches":{"album":[
          {"name":"Kid A","artist":"レディオヘッド","url":"https://last.fm/x",
           "image":[{"#text":"","size":"small"},{"#text":"","size":"medium"},
                    {"#text":"","size":"large"},{"#text":"","size":"extralarge"}],
           "streamable":"0","mbid":""}]}}}
        """
        let decoded = try JSONDecoder().decode(SearchResults.self, from: Data(json.utf8))
        let album = try XCTUnwrap(decoded.results.albummatches?.album.first)

        XCTAssertEqual(album.artist, "レディオヘッド")
        XCTAssertNil(album.coverURL)
    }

    func testEmptyMatchesDecodeToAnEmptyListRatherThanFailing() throws {
        let json = """
        {"results":{"opensearch:totalResults":"0","albummatches":{"album":[]}}}
        """
        let decoded = try JSONDecoder().decode(SearchResults.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.results.albummatches?.album.count, 0)
    }

    func testChartResponsesDecode() throws {
        let artists = """
        {"artists":{"artist":[{"name":"Ariana Grande","listeners":"4664549","mbid":"f4fdbb4c",
        "url":"https://last.fm/a","streamable":"0","image":[]}]}}
        """
        let a = try JSONDecoder().decode(ArtistResponse.self, from: Data(artists.utf8))
        XCTAssertEqual(a.artists.artist.first?.name, "Ariana Grande")

        let tracks = """
        {"tracks":{"track":[{"name":"the cure","duration":"297",
        "artist":{"name":"Lady Gaga","url":"https://last.fm/t"}}]}}
        """
        let t = try JSONDecoder().decode(TrackInfo.self, from: Data(tracks.utf8))
        XCTAssertEqual(t.tracks.track.first?.artist.name, "Lady Gaga")
    }

    /// Last.fm signals failure with this shape rather than the one that was asked
    /// for. Decoding it is what turns a 403 into a readable message.
    func testErrorEnvelopeIsDistinguishableFromASuccessfulResponse() throws {
        let error = Data(#"{"message":"Invalid API key","error":10}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(SearchResults.self, from: error),
                             "an error body must not decode as results")
    }
}
