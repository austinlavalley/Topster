//
//  CoverResolutionTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// `Album.coverURL` decides whether a cell shows art or a placeholder. Getting it
/// wrong is what made albums spin forever, so the edges are worth pinning down.
final class CoverResolutionTests: XCTestCase {

    private func album(small: String = "", medium: String = "",
                       large: String = "", extralarge: String = "") throws -> Album {
        let json = """
        {
          "name": "Test Album",
          "artist": "Test Artist",
          "url": "https://last.fm/test",
          "streamable": "0",
          "mbid": "",
          "image": [
            {"#text": "\(small)", "size": "small"},
            {"#text": "\(medium)", "size": "medium"},
            {"#text": "\(large)", "size": "large"},
            {"#text": "\(extralarge)", "size": "extralarge"}
          ]
        }
        """
        return try JSONDecoder().decode(Album.self, from: Data(json.utf8))
    }

    func testPrefersExtralargeOverLarge() throws {
        let a = try album(large: "https://example.com/174.png",
                          extralarge: "https://example.com/300.png")

        XCTAssertEqual(a.coverURL?.absoluteString, "https://example.com/300.png",
                       "300px art should win: grid cells render around 354 physical pixels")
    }

    func testFallsBackToLargeWhenExtralargeIsEmpty() throws {
        let a = try album(large: "https://example.com/174.png", extralarge: "")

        XCTAssertEqual(a.coverURL?.absoluteString, "https://example.com/174.png")
    }

    /// The case behind the load-time complaints. Last.fm returns an empty string
    /// rather than omitting the field, for a quarter to two thirds of any result set.
    func testEmptyStringsResolveToNilRatherThanABogusURL() throws {
        let a = try album()

        XCTAssertNil(a.coverURL, "an empty string must not become a URL that spins forever")
    }

    func testWhitespaceOnlyIsTreatedAsAbsent() throws {
        let a = try album(large: "   ", extralarge: "  ")

        XCTAssertNil(a.coverURL)
    }

    func testMissingImageArrayEntriesDoNotCrash() throws {
        let json = """
        {"name":"n","artist":"a","url":"u","streamable":"0","mbid":"","image":[]}
        """
        let a = try JSONDecoder().decode(Album.self, from: Data(json.utf8))

        XCTAssertNil(a.coverURL)
    }

    /// Album names collide constantly. A "greatest hits" search returns fifty albums
    /// sharing one name, which is why ForEach cannot key on it.
    func testAlbumsWithIdenticalNamesStillHaveDistinctIdentities() throws {
        let one = try album(extralarge: "https://example.com/a.png")
        let two = try album(extralarge: "https://example.com/a.png")

        XCTAssertEqual(one.name, two.name)
        XCTAssertNotEqual(one.id, two.id)
    }
}
