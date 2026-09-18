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

    // MARK: - Fallback sizes

    /// The case behind a cover showing the music note while Last.fm had art:
    /// the 300px file 404ed and nothing else was tried.
    func testFallbacksAreTheSmallerSizesLargestFirst() throws {
        let a = try album(small: "https://example.com/34.png",
                          medium: "https://example.com/64.png",
                          large: "https://example.com/174.png",
                          extralarge: "https://example.com/300.png")

        XCTAssertEqual(a.coverFallbackURLs.map(\.absoluteString),
                       ["https://example.com/174.png", "https://example.com/64.png"],
                       "34px is too small to stand in for a grid cell")
    }

    func testFallbacksNeverRepeatThePrimary() throws {
        let a = try album(medium: "https://example.com/64.png",
                          large: "https://example.com/174.png", extralarge: "")

        XCTAssertEqual(a.coverURL?.absoluteString, "https://example.com/174.png")
        XCTAssertEqual(a.coverFallbackURLs.map(\.absoluteString), ["https://example.com/64.png"])
    }

    /// A grid cell reads this to decide whether the cover it found in memory
    /// still needs its full-size art. Getting it wrong either strands a 174px
    /// stand-in for the session or refetches every cover on every appearance.
    func testTheMemoryCacheKnowsAStandInFromTheRealThing() {
        let primary = "https://example.com/300x300/\(UUID().uuidString).png"
        let smaller = URL(string: "https://example.com/174s/cover.png")!

        XCTAssertNil(CoverMemoryCache.standInSource(for: primary), "nothing cached yet")

        CoverMemoryCache.store(UIImage(), for: primary, from: smaller)
        XCTAssertEqual(CoverMemoryCache.standInSource(for: primary), smaller)

        CoverMemoryCache.store(UIImage(), for: primary)
        XCTAssertNil(CoverMemoryCache.standInSource(for: primary),
                     "the full-size art replaced the stand-in")

        CoverMemoryCache.store(UIImage(), for: primary, from: URL(string: primary)!)
        XCTAssertNil(CoverMemoryCache.standInSource(for: primary),
                     "an image from its own URL is not a stand-in")
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
