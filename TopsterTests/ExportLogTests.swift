//
//  ExportLogTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// The export log sends a copy of each saved grid to topster.app with no
/// identifier. These pin down what goes in it, and above all what does not.
final class ExportLogTests: XCTestCase {

    private func album(_ artist: String, _ name: String, cover: String? = nil) -> Album {
        let image = cover.map { url in [AlbumImage(text: url, size: "extralarge")] } ?? []
        return Album(name: name, artist: artist, url: "", image: image, streamable: "0", mbid: "")
    }

    private func grid(_ count: Int) -> [Int: Album?] {
        Dictionary(uniqueKeysWithValues: (1...count).map { key in (key, Album?.none) })
    }

    func testPayloadListsFilledSlotsInOrder() {
        var slots = grid(25)
        slots[1] = album("Radiohead", "OK Computer",
                         cover: "https://lastfm.freetls.fastly.net/i/u/300x300/ok.png")
        slots[7] = album("Björk", "Homogenic")
        slots[25] = album("Nas", "Illmatic")

        let payload = ExportLog.payload(grid: slots, layout: .twentyFive, labels: .none,
                                        darkBackground: false, appVersion: "1.7.1")

        XCTAssertEqual(payload.slots, [
            ExportLog.Slot(slot: 1, artist: "Radiohead", album: "OK Computer",
                           cover: "https://lastfm.freetls.fastly.net/i/u/300x300/ok.png"),
            ExportLog.Slot(slot: 7, artist: "Björk", album: "Homogenic", cover: nil),
            ExportLog.Slot(slot: 25, artist: "Nas", album: "Illmatic", cover: nil),
        ])
    }

    /// The stored dictionary keeps its extra keys after a switch from the 42 to
    /// a smaller layout, and the export never draws them. Neither may the log.
    func testPayloadStopsAtTheLayoutsSlotCount() {
        var slots = grid(42)
        slots[25] = album("Shown", "Last slot of the 25")
        slots[26] = album("Hidden", "Left over from the 42")

        let payload = ExportLog.payload(grid: slots, layout: .twentyFive, labels: .none,
                                        darkBackground: false, appVersion: "1.7.1")

        XCTAssertEqual(payload.slots.map(\.slot), [25])
    }

    func testPayloadCarriesTheExportOptions() {
        var slots = grid(20)
        slots[1] = album("A", "B")

        let payload = ExportLog.payload(grid: slots, layout: .twentyWide, labels: .list,
                                        darkBackground: true, appVersion: "1.7.1")

        XCTAssertEqual(payload.layout, "twentyWide")
        XCTAssertEqual(payload.labels, "list")
        XCTAssertEqual(payload.background, "dark")
        XCTAssertEqual(payload.appVersion, "1.7.1")
    }

    /// The privacy promise, enforced like the analytics one: the body carries
    /// these keys and no others, so nothing that could identify someone can be
    /// added to it without this test being changed on purpose.
    func testTheBodyCarriesOnlyTheAgreedKeys() throws {
        var slots = grid(25)
        slots[1] = album("A", "B", cover: "https://lastfm.freetls.fastly.net/i/u/300x300/x.png")
        slots[2] = album("C", "D")
        let payload = ExportLog.payload(grid: slots, layout: .twentyFive, labels: .overlay,
                                        darkBackground: false, appVersion: "1.7.1")

        let request = try XCTUnwrap(ExportLog.request(for: payload, to: ExportLog.endpoint))
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])

        XCTAssertEqual(Set(json.keys), ["layout", "labels", "background", "app_version", "slots"])
        let sent = try XCTUnwrap(json["slots"] as? [[String: Any]])
        for slot in sent {
            XCTAssertTrue(Set(slot.keys).isSubset(of: ["slot", "artist", "album", "cover"]),
                          "unexpected slot keys \(slot.keys.sorted())")
        }
    }

    func testTheRequestIsAJSONPostToTheEndpoint() throws {
        var slots = grid(20)
        slots[3] = album("Talking Heads", "Remain in Light")
        let payload = ExportLog.payload(grid: slots, layout: .twenty, labels: .none,
                                        darkBackground: false, appVersion: "1.7.1")

        let request = try XCTUnwrap(ExportLog.request(for: payload, to: ExportLog.endpoint))

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.url, URL(string: "https://topster.app/api/exports"))
    }

    func testAnEmptyGridSendsNothing() {
        let payload = ExportLog.payload(grid: grid(25), layout: .twentyFive, labels: .none,
                                        darkBackground: false, appVersion: "1.7.1")

        XCTAssertNil(ExportLog.request(for: payload, to: ExportLog.endpoint))
    }

    /// Tests, UI test runs and screenshot runs are debug builds. They must not
    /// post into the real gallery unless someone points them somewhere.
    func testDebugBuildsSendNowhereByDefault() {
        UserDefaults.standard.removeObject(forKey: "ExportLogEndpoint")

        XCTAssertNil(ExportLog.destination)
    }
}
