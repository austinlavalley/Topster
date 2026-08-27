//
//  CoverFetcher.swift
//  Topster
//
//  Created by Austin Lavalley on 8/26/26.
//

import UIKit


/// Fetches one cover, retrying a request that never completed.
///
/// This exists as its own type so the retry can be tested. It used to live inside
/// `InternetImage.load()`, private to a SwiftUI view and unreachable from a test,
/// which meant the one behaviour this whole change was made for was the one thing
/// nothing verified.
///
/// The bug it answers, reported against the live 1.5.0 build: two covers of six
/// showed placeholders on launch while the export showed all six. The URLs were
/// fine. `AsyncImage` gets a single attempt and stays in `.failure` forever when
/// that attempt is lost, so a cover that was merely unlucky looked permanently dead.
enum CoverFetcher {

    /// Swappable so tests can stub the network with a `URLProtocol`. Production
    /// never reassigns it.
    static var session: URLSession = .shared

    static let maxAttempts = 3

    enum Outcome: Equatable {
        /// Loaded, with the number of attempts it took.
        case image(UIImage, attempts: Int)
        /// The server answered and what came back is not an image. A retry will not
        /// change that, and the URL is worth remembering as dead.
        case gone
        /// Every attempt failed to complete. Worth trying again later.
        case unreachable

        static func == (lhs: Outcome, rhs: Outcome) -> Bool {
            switch (lhs, rhs) {
            case let (.image(_, a), .image(_, b)): return a == b
            case (.gone, .gone), (.unreachable, .unreachable): return true
            default: return false
            }
        }
    }

    /// Retries only requests that never completed. A definitive answer from the
    /// server is taken at face value the first time.
    ///
    /// `backoff` is injectable so tests do not wait out real delays.
    static func fetch(_ url: URL,
                      backoff: (Int) async -> Void = { attempt in
                          try? await Task.sleep(nanoseconds: UInt64(attempt) * 400_000_000)
                      }) async -> Outcome {

        let request = URLRequest(url: url)

        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                await backoff(attempt)
            }

            if Task.isCancelled { return .unreachable }

            do {
                let (data, response) = try await session.data(for: request)

                if let image = UIImage(data: data) {
                    URLCache.shared.storeCachedResponse(
                        CachedURLResponse(response: response, data: data), for: request)
                    return .image(image, attempts: attempt + 1)
                }

                // A 404, a 5xx, or a 200 carrying something undecodable.
                return .gone

            } catch {
                continue
            }
        }

        return .unreachable
    }
}
