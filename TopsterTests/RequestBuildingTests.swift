//
//  RequestBuildingTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// Every one of these is a query that used to come out wrong. The old code
/// interpolated the raw search string into a URL, and searchAlbums swapped spaces
/// for dashes, which changed what was being searched for.
final class RequestBuildingTests: XCTestCase {

    private let networker = Networker()

    private func query(for album: String) throws -> String {
        let url = try networker.buildURL(method: "album.search", parameters: ["album": album])
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery ?? ""
    }

    func testSpacesAreEncoded() throws {
        XCTAssertTrue(try query(for: "in rainbows").contains("album=in%20rainbows"))
    }

    func testAccentedCharactersAreEncoded() throws {
        XCTAssertTrue(try query(for: "Sigur Rós").contains("album=Sigur%20R%C3%B3s"))
    }

    /// Unencoded, this split the query and Last.fm searched for "Simon " alone.
    func testAmpersandIsEncodedRatherThanSplittingTheQuery() throws {
        let q = try query(for: "Simon & Garfunkel")

        XCTAssertTrue(q.contains("album=Simon%20%26%20Garfunkel"), q)
        XCTAssertFalse(q.contains("album=Simon%20&%20Garfunkel"),
                       "a bare & would start a new query parameter")
    }

    /// Unencoded, everything after # became a fragment, which dropped the API key
    /// entirely and returned 403.
    func testHashIsEncodedRatherThanTruncatingTheURL() throws {
        let q = try query(for: "#1 Record")

        XCTAssertTrue(q.contains("album=%231%20Record"), q)
        XCTAssertTrue(q.contains("api_key="), "the API key must survive a # in the query")
    }

    /// URLComponents leaves + alone because it is legal in a query, but Last.fm
    /// reads a literal + as a space. Verified against the live API.
    func testPlusIsEncodedBecauseLastfmReadsItAsASpace() throws {
        let q = try query(for: "Wu-Tang + Friends")

        XCTAssertTrue(q.contains("%2B"), q)
    }

    func testSlashSurvivesUnharmed() throws {
        XCTAssertTrue(try query(for: "AC/DC").contains("album=AC/DC"))
    }

    func testEveryRequestCarriesMethodKeyAndFormat() throws {
        let q = try query(for: "anything")

        XCTAssertTrue(q.contains("method=album.search"))
        XCTAssertTrue(q.contains("api_key="))
        XCTAssertTrue(q.contains("format=json"))
    }

    func testArtistSearchUsesTheArtistParameter() throws {
        let url = try networker.buildURL(method: "artist.search", parameters: ["artist": "radiohead"])

        XCTAssertTrue(url.absoluteString.contains("method=artist.search"))
        XCTAssertTrue(url.absoluteString.contains("artist=radiohead"))
    }
}
