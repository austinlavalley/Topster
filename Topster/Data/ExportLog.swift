//
//  ExportLog.swift
//  Topster
//

import Foundation

/// A copy of each grid saved to Photos, sent to topster.app with no identifier.
///
/// The point is to see what people make: which layouts get finished and what
/// goes on them. It is deliberately separate from `Analytics`, which never
/// carries album names, and it carries nothing that ties a grid to a person
/// or to an Amplitude install: no device ID, no install ID, no session, no
/// timestamp beyond the day the server writes down.
///
/// Fire and forget. It is called only after Photos has confirmed the save, it
/// cannot delay or change what the export sheet shows, and a failed send is
/// dropped rather than retried.
enum ExportLog {

    struct Slot: Encodable, Equatable {
        let slot: Int
        let artist: String
        let album: String
        let cover: String?
    }

    struct Payload: Encodable, Equatable {
        let layout: String
        let labels: String
        let background: String
        let appVersion: String
        let slots: [Slot]

        enum CodingKeys: String, CodingKey {
            case layout, labels, background, slots
            case appVersion = "app_version"
        }
    }

    static let endpoint = URL(string: "https://topster.app/api/exports")!

    /// Where sends go. Debug and simulator builds send nothing unless pointed
    /// somewhere on purpose with `-ExportLogEndpoint <url>`, so UI test and
    /// screenshot runs never land in the real gallery.
    static var destination: URL? {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "ExportLogEndpoint").flatMap(URL.init(string:))
        #else
        return endpoint
        #endif
    }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    /// The grid as the export draws it. Stops at the layout's slot count,
    /// because the stored dictionary keeps extra keys after a switch to a
    /// smaller layout and the export views never show them.
    static func payload(grid: [Int: Album?], layout: GridType, labels: ExportLabels,
                        darkBackground: Bool, appVersion: String) -> Payload {
        let slots = (1...layout.slotCount).compactMap { key -> Slot? in
            guard let album = grid[key] ?? nil else { return nil }
            return Slot(slot: key, artist: album.artist, album: album.name,
                        cover: album.coverURL?.absoluteString)
        }
        return Payload(layout: layout.rawValue, labels: labels.rawValue,
                       background: darkBackground ? "dark" : "light",
                       appVersion: appVersion, slots: slots)
    }

    /// Nil for an empty grid, which has nothing worth seeing.
    static func request(for payload: Payload, to url: URL) -> URLRequest? {
        guard !payload.slots.isEmpty, let body = try? JSONEncoder().encode(payload) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    /// Ephemeral, so the request carries no cookies and leaves nothing cached.
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    static func send(_ payload: Payload) {
        guard let url = destination, let request = request(for: payload, to: url) else { return }
        session.dataTask(with: request).resume()
    }
}
