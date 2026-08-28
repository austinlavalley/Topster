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

    /// Shape taken from a real Deezer `search/album` response. Only title and
    /// artist name are read; everything else must be ignorable, not fatal.
    func testDeezerSearchDecodes() throws {
        let json = """
        {"data":[{"id":355777,"title":"Blue","link":"https://www.deezer.com/album/355777",
        "cover":"https://api.deezer.com/album/355777/image",
        "cover_medium":"https://cdn-images.dzcdn.net/250x250.jpg",
        "record_type":"album","explicit_lyrics":false,
        "artist":{"id":464,"name":"Joni Mitchell","tracklist":"https://api.deezer.com/artist/464/top"},
        "type":"album"}],"total":300,"next":"https://api.deezer.com/search/album?q=blue&index=25"}
        """
        let decoded = try JSONDecoder().decode(DeezerSearchResponse.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.data.count, 1)
        XCTAssertEqual(decoded.data.first?.title, "Blue")
        XCTAssertEqual(decoded.data.first?.artist.name, "Joni Mitchell")
    }

    /// `album.getInfo`, which backfills albums Last.fm's search misses. Its
    /// `artist` is a plain string where the search shape nests an object.
    func testAlbumInfoDecodesAndMapsToAnAlbumWithArt() throws {
        let json = """
        {"album":{"artist":"The Rolling Stones","mbid":"4839e1b7",
        "name":"Blue & Lonesome","url":"https://www.last.fm/music/x",
        "image":[{"#text":"https://example.com/174.png","size":"large"},
                 {"#text":"https://example.com/300.png","size":"extralarge"}],
        "listeners":"263553","playcount":"5361040"}}
        """
        let decoded = try JSONDecoder().decode(AlbumInfoResponse.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.album.name, "Blue & Lonesome")
        XCTAssertEqual(decoded.album.artist, "The Rolling Stones")
        XCTAssertEqual(decoded.album.image.count, 2)
        XCTAssertEqual(decoded.album.listeners, "263553",
                       "listeners is the ranking axis and must survive decoding")
    }

    /// Deezer signals failure with an error *object*, unlike Last.fm's flat code.
    /// It must not decode as a successful search, so the hint comes back nil
    /// rather than empty-but-plausible.
    func testDeezerErrorEnvelopeDoesNotDecodeAsResults() {
        let error = Data(#"{"error":{"type":"Exception","message":"Quota limit exceeded","code":4}}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(DeezerSearchResponse.self, from: error))
    }

    /// Last.fm signals failure with this shape rather than the one that was asked
    /// for. Decoding it is what turns a 403 into a readable message.
    func testErrorEnvelopeIsDistinguishableFromASuccessfulResponse() throws {
        let error = Data(#"{"message":"Invalid API key","error":10}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(SearchResults.self, from: error),
                             "an error body must not decode as results")
    }
}
