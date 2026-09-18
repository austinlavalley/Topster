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

    /// Longest a cover request may go without receiving a byte. The default is
    /// 60 seconds, and with three attempts a stalled 300px file kept a spinner
    /// up for three minutes. A cold resize that fails answers 404 within 5 to
    /// 10 seconds (probed 18 Sep 2026), so a request silent for longer than
    /// this is not coming back soon.
    static let requestTimeout: TimeInterval = 10

    /// How long each size gets on its own before the next smaller one starts
    /// alongside it. Probed 18 Sep 2026: a cover the CDN already holds answers
    /// in 0.1 to 0.3 s, and one it has to make takes 2 s or more when it works
    /// at all. So 300px starts at once, 174px at 1.5 s and 64px at 3 s, which
    /// puts some version of the art on screen within about 5 s.
    static let headStartNanoseconds: UInt64 = 1_500_000_000

    enum Outcome: Equatable {
        /// Loaded, with the number of attempts it took.
        case image(UIImage, attempts: Int)
        /// The server answered and what came back is not an image. A retry will not
        /// change that, and the URL is worth remembering as dead.
        case gone
        /// Every attempt failed to complete. Worth trying again later.
        case unreachable
        /// The cell went away before an attempt finished. Nothing was learned about
        /// the cover, so this is not a failure and callers must not report it as one.
        case cancelled

        static func == (lhs: Outcome, rhs: Outcome) -> Bool {
            switch (lhs, rhs) {
            case let (.image(_, a), .image(_, b)): return a == b
            case (.gone, .gone), (.unreachable, .unreachable), (.cancelled, .cancelled):
                return true
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

        let request = URLRequest(url: url, timeoutInterval: requestTimeout)

        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                await backoff(attempt)
            }

            if Task.isCancelled { return .cancelled }

            do {
                let (data, response) = try await session.data(for: request)

                if let image = UIImage(data: data) {
                    URLCache.shared.storeCachedResponse(
                        CachedURLResponse(response: response, data: data), for: request)
                    return .image(image, attempts: attempt + 1)
                }

                // Only a definitive answer marks a cover dead: the resource is
                // gone (404/410), or the server succeeded and what it served is
                // not an image. A 5xx is the server having a bad moment, and
                // treating it as death was observed writing off a perfectly
                // good cover for a whole session over one CDN error page; it
                // counts as a failed attempt instead.
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 404 || status == 410 || (200..<300).contains(status) {
                    return .gone
                }
                continue

            } catch {
                // A cancelled request throws here rather than tripping the check
                // above. Letting it fall through to .unreachable is what turned
                // cover_fetch_failed into a measure of scrolling.
                if Task.isCancelled { return .cancelled }
                continue
            }
        }

        return .unreachable
    }

    /// What came of trying several sizes of one cover.
    struct LadderResult {
        /// `.image` with the largest size that loaded, `.gone` only when every
        /// size was definitively gone, and `.unreachable` when at least one
        /// might still come back.
        let outcome: Outcome
        /// The URL the final image came from, when there is one.
        let source: URL?
        /// Sizes the server said do not exist, for the caller to stop asking.
        let dead: [URL]
    }

    private enum LadderEvent {
        case finished(index: Int, Outcome)
        /// The head start for the size at `index` ran out.
        case headStartOver(index: Int)
    }

    /// Races the sizes of one cover, largest first, and reports each image
    /// that beats the best one so far through `onImage`.
    ///
    /// Each size gets `headStart` alone before the next smaller one joins, and
    /// a size that fails hands over at once instead of waiting that out. A
    /// smaller image goes on screen when it arrives, and the larger request
    /// keeps running, so a slow 300px file replaces the 174px stand-in rather
    /// than being abandoned. It returns once nothing larger than the best
    /// image is still in flight. See `Album.coverFallbackURLs` for why the
    /// 300px size fails while the smaller ones load.
    static func fetchBest(of candidates: [URL],
                          headStart: UInt64 = headStartNanoseconds,
                          backoff: @escaping (Int) async -> Void = { attempt in
                              try? await Task.sleep(nanoseconds: UInt64(attempt) * 400_000_000)
                          },
                          onImage: @escaping @MainActor (UIImage, URL) -> Void) async -> LadderResult {
        await withTaskGroup(of: LadderEvent.self) { group in
            var launched = 0
            var running: Set<Int> = []
            var best: (index: Int, image: UIImage, attempts: Int)?
            var dead: [URL] = []
            var anyUnreachable = false
            var cancelled = false

            func launchNext() {
                guard launched < candidates.count, !Task.isCancelled else { return }
                let index = launched
                let url = candidates[index]
                launched += 1
                running.insert(index)

                group.addTask { .finished(index: index, await fetch(url, backoff: backoff)) }
                if index + 1 < candidates.count {
                    group.addTask {
                        try? await Task.sleep(nanoseconds: headStart)
                        return .headStartOver(index: index)
                    }
                }
            }

            launchNext()

            // next() rather than for-await, because the loop adds to the group.
            while let event = await group.next() {
                switch event {
                case let .headStartOver(index):
                    // Only if this size is still the newest one running and
                    // nothing has loaded. A size that already failed started
                    // the next one itself.
                    if best == nil && launched == index + 1 {
                        launchNext()
                    }

                case let .finished(index, outcome):
                    running.remove(index)

                    switch outcome {
                    case let .image(image, attempts):
                        if best == nil || index < best!.index {
                            best = (index, image, attempts)
                            await onImage(image, candidates[index])
                        }
                    case .gone:
                        dead.append(candidates[index])
                        if best == nil { launchNext() }
                    case .unreachable:
                        anyUnreachable = true
                        if best == nil { launchNext() }
                    case .cancelled:
                        cancelled = true
                    }
                }

                // Every size launched has answered and none is left to start, so
                // the head starts still pending have nothing to hand over to.
                if cancelled || running.isEmpty { break }

                // Done once no request that could beat the best image is left.
                if let best, !running.contains(where: { index in index < best.index }) {
                    break
                }
            }

            // Stops whatever is left: smaller sizes that lost and pending head starts.
            group.cancelAll()

            if let best {
                return LadderResult(outcome: .image(best.image, attempts: best.attempts),
                                    source: candidates[best.index], dead: dead)
            }
            if cancelled || Task.isCancelled {
                return LadderResult(outcome: .cancelled, source: nil, dead: dead)
            }
            return LadderResult(outcome: anyUnreachable ? .unreachable : .gone,
                                source: nil, dead: dead)
        }
    }
}
