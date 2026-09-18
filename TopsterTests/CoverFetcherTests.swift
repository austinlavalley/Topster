//
//  CoverFetcherTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

/// Stands in for the network so a request can be made to fail on demand.
final class StubURLProtocol: URLProtocol {

    /// Called once per request, with the number of requests seen so far including
    /// this one. Throw to simulate a request that never completes.
    static var respond: ((Int, URLRequest) throws -> (HTTPURLResponse, Data))?
    static var requestCount = 0

    /// Seconds to hold a request before answering it, for racing sizes against
    /// each other. Nil answers at once. A long delay stands in for a request
    /// that hangs until it is cancelled.
    static var delay: ((URLRequest) -> TimeInterval)?

    /// Only requests whose URL contains this are counted and answered. A
    /// request cancelled in one test can reach `startLoading` after the next
    /// test has reset the count, and it bumped that count mid-test: seen once
    /// on 18 Sep 2026 under a full run, as a fetch that succeeded on its
    /// second attempt where the stub only allowed the third.
    static var scope = ""

    static func reset(scope: String = "") {
        respond = nil
        requestCount = 0
        delay = nil
        Self.scope = scope
    }

    private var stopped = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard request.url?.absoluteString.contains(Self.scope) == true else {
            client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
            return
        }

        Self.requestCount += 1
        let count = Self.requestCount

        let wait = Self.delay?(request) ?? 0
        guard wait > 0 else {
            answer(count)
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + wait) { [weak self] in
            guard let self, !self.stopped else { return }
            self.answer(count)
        }
    }

    private func answer(_ count: Int) {
        guard let respond = Self.respond else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try respond(count, request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        stopped = true
    }
}


/// The behaviour this whole change was made for.
///
/// A cover that is perfectly fine but loses its first request used to look
/// permanently dead: `AsyncImage` gets one attempt and stays in `.failure`. Reported
/// against the live 1.5.0 build as two covers of six showing placeholders while the
/// export showed all six.
///
/// These are the only tests that exercise it, because it cannot be reproduced
/// against a real server on demand.
final class CoverFetcherTests: XCTestCase {

    /// Unique per test, since XCTest makes a fresh instance for each one. Every
    /// URL below carries it, so a straggler from an earlier test is ignored.
    private let run = UUID().uuidString

    private var url: URL { URL(string: "https://example.com/\(run)/cover.png")! }

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset(scope: run)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        CoverFetcher.session = URLSession(configuration: config)
    }

    override func tearDown() {
        CoverFetcher.session = .shared
        StubURLProtocol.reset()
        super.tearDown()
    }

    private func ok(_ request: URLRequest) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                       httpVersion: nil, headerFields: nil)!
        return (response, Self.pngBytes)
    }

    private func status(_ code: Int, _ request: URLRequest) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(url: request.url!, statusCode: code,
                                       httpVersion: nil, headerFields: nil)!
        return (response, Data("not an image".utf8))
    }

    /// No delay between attempts, so the tests do not wait out real backoff.
    private func fetch() async -> CoverFetcher.Outcome {
        await CoverFetcher.fetch(url, backoff: { _ in })
    }

    // MARK: - The bug

    func testACoverThatLosesItsFirstRequestStillLoads() async {
        StubURLProtocol.respond = { attempt, request in
            if attempt == 1 { throw URLError(.networkConnectionLost) }
            return self.ok(request)
        }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .image(UIImage(), attempts: 2),
                       "a cover that lost one request must not be written off")
        XCTAssertEqual(StubURLProtocol.requestCount, 2)
    }

    func testACoverThatLosesTwoRequestsStillLoads() async {
        StubURLProtocol.respond = { attempt, request in
            if attempt < 3 { throw URLError(.timedOut) }
            return self.ok(request)
        }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .image(UIImage(), attempts: 3))
        XCTAssertEqual(StubURLProtocol.requestCount, 3)
    }

    func testAWorkingCoverIsNotRequestedTwice() async {
        StubURLProtocol.respond = { _, request in self.ok(request) }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .image(UIImage(), attempts: 1))
        XCTAssertEqual(StubURLProtocol.requestCount, 1, "no retry when the first attempt works")
    }

    // MARK: - Giving up correctly

    func testAnUnreachableCoverGivesUpAfterThreeAttempts() async {
        StubURLProtocol.respond = { _, _ in throw URLError(.notConnectedToInternet) }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .unreachable)
        XCTAssertEqual(StubURLProtocol.requestCount, CoverFetcher.maxAttempts)
    }

    /// A 404 is an answer, not a lost request. Retrying it would waste two more
    /// round trips on every dead cover in an old grid, and about 4% of them are dead.
    func testA404IsNotRetried() async {
        StubURLProtocol.respond = { _, request in self.status(404, request) }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .gone)
        XCTAssertEqual(StubURLProtocol.requestCount, 1, "a definitive answer is taken once")
    }

    func testA200CarryingSomethingUndecodableIsNotRetried() async {
        StubURLProtocol.respond = { _, request in self.status(200, request) }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .gone)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
    }

    /// A 5xx is the server having a bad moment, not a verdict on the cover.
    /// Treating it as death wrote off a perfectly good cover for a whole
    /// session over one CDN error page, observed on device 28 Aug 2026.
    func testA503IsRetriedAndReportedUnreachableRatherThanDead() async {
        StubURLProtocol.respond = { _, request in self.status(503, request) }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .unreachable,
                       "a server error must stay retryable, never a death sentence")
        XCTAssertEqual(StubURLProtocol.requestCount, CoverFetcher.maxAttempts)
    }

    /// The recovery case that motivates the distinction: one 5xx, then fine.
    func testACoverBehindATransient503StillLoads() async {
        StubURLProtocol.respond = { attempt, request in
            attempt == 1 ? self.status(503, request) : self.ok(request)
        }

        let outcome = await fetch()

        XCTAssertEqual(outcome, .image(UIImage(), attempts: 2))
        XCTAssertEqual(StubURLProtocol.requestCount, 2)
    }

    // MARK: - Cancellation is not failure

    /// The behaviour 1.6.1 exists for.
    ///
    /// A cover whose cell went away tells us nothing about that cover. Reporting it
    /// as unreachable made cover_fetch_failed climb with engagement rather than with
    /// CDN trouble: 353 events from two users in a day, on an app that was fine.
    ///
    /// Both cancellation paths land here. If cancel() beats the task body, the check
    /// at the top of the first attempt catches it; if the request goes out first, the
    /// stub's throw reaches the catch, which checks again. Either way the answer must
    /// not be .unreachable.
    func testACancelledFetchIsNotReportedAsAFailure() async {
        StubURLProtocol.respond = { _, _ in throw URLError(.networkConnectionLost) }

        let target = url
        let task = Task { await CoverFetcher.fetch(target, backoff: { _ in }) }
        task.cancel()

        let outcome = await task.value

        XCTAssertEqual(outcome, .cancelled,
                       "a cancelled fetch is not a failed one and must not be counted as one")
    }

    // MARK: - Racing the sizes

    private var large: URL { URL(string: "https://example.com/\(run)/300x300/cover.png")! }
    private var medium: URL { URL(string: "https://example.com/\(run)/174s/cover.png")! }
    private var small: URL { URL(string: "https://example.com/\(run)/64s/cover.png")! }

    /// Every image `fetchBest` put on screen, in order.
    @MainActor private final class Shown {
        var urls: [URL] = []
        nonisolated init() {}
    }

    private func fetchBest(headStart: TimeInterval,
                           onImage: @escaping @MainActor (URL) -> Void = { _ in })
    async -> CoverFetcher.LadderResult {
        await CoverFetcher.fetchBest(of: [large, medium, small],
                                     headStart: UInt64(headStart * 1_000_000_000),
                                     backoff: { _ in }) { _, url in onImage(url) }
    }

    /// Seen on device 17 Sep 2026: Last.fm's CDN 404ed the 300px file and cached
    /// that 404 for hours, while the 174px file for the same art loaded fine.
    /// The head start here is a minute, so only an immediate handover passes.
    func testA404OnTheLargeSizeHandsOverWithoutWaitingOutTheHeadStart() async {
        StubURLProtocol.respond = { _, request in
            request.url == self.large ? self.status(404, request) : self.ok(request)
        }

        let started = Date()
        let result = await fetchBest(headStart: 60)

        XCTAssertEqual(result.outcome, .image(UIImage(), attempts: 1),
                       "a 300px 404 must not hide art that exists at 174px")
        XCTAssertEqual(result.source, medium)
        XCTAssertEqual(result.dead, [large])
        XCTAssertEqual(StubURLProtocol.requestCount, 2, "the smallest size is never asked for")
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }

    /// The three-minute spinner. A 300px request that never answers must not
    /// keep the art off screen past its head start.
    func testAHangingLargeSizeIsCoveredByTheNextSizeAfterItsHeadStart() async {
        StubURLProtocol.delay = { request in request.url == self.large ? 3600 : 0 }
        StubURLProtocol.respond = { _, request in self.ok(request) }

        let shown = Shown()
        let mediumShown = expectation(description: "174px on screen")
        let task = Task {
            await fetchBest(headStart: 0.05) { url in
                shown.urls.append(url)
                if url == self.medium { mediumShown.fulfill() }
            }
        }

        await fulfillment(of: [mediumShown], timeout: 5)
        task.cancel()
        let result = await task.value

        let urls = await shown.urls
        XCTAssertEqual(urls, [medium])
        XCTAssertEqual(result.source, medium)
        XCTAssertEqual(StubURLProtocol.requestCount, 2, "64px never starts once 174px is showing")
    }

    /// The 300px file is slow, not gone. It keeps loading behind the stand-in
    /// and replaces it when it arrives.
    func testALateLargeSizeReplacesTheStandIn() async {
        StubURLProtocol.delay = { request in request.url == self.large ? 0.4 : 0 }
        StubURLProtocol.respond = { _, request in self.ok(request) }

        let shown = Shown()
        let result = await fetchBest(headStart: 0.05) { url in shown.urls.append(url) }

        let urls = await shown.urls
        XCTAssertEqual(urls, [medium, large])
        XCTAssertEqual(result.source, large)
    }

    func testAnUnreachableLargeSizeHandsOverToo() async {
        StubURLProtocol.respond = { _, request in
            if request.url == self.large { throw URLError(.timedOut) }
            return self.ok(request)
        }

        let result = await fetchBest(headStart: 60)

        XCTAssertEqual(result.source, medium)
        XCTAssertEqual(result.dead, [], "a timeout is not a verdict on the 300px file")
    }

    func testTheCoverIsGoneOnlyWhenEverySizeIsGone() async {
        StubURLProtocol.respond = { _, request in self.status(404, request) }

        let started = Date()
        let result = await fetchBest(headStart: 60)

        XCTAssertEqual(result.outcome, .gone)
        XCTAssertNil(result.source)
        XCTAssertEqual(result.dead, [large, medium, small])
        XCTAssertLessThan(Date().timeIntervalSince(started), 5,
                          "the placeholder must not wait on head starts with nothing left to start")
    }

    /// One size might still come back, so the loader keeps retrying rather than
    /// drawing the placeholder.
    func testOneDeadSizeAndOneUnreachableIsUnreachable() async {
        StubURLProtocol.respond = { _, request in
            if request.url == self.large { return self.status(404, request) }
            throw URLError(.networkConnectionLost)
        }

        let result = await fetchBest(headStart: 60)

        XCTAssertEqual(result.outcome, .unreachable)
        XCTAssertEqual(result.dead, [large])
    }

    func testAWorkingLargeSizeNeverTouchesTheFallbacks() async {
        StubURLProtocol.respond = { _, request in self.ok(request) }

        let started = Date()
        let result = await fetchBest(headStart: 1)

        XCTAssertEqual(result.source, large)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
        XCTAssertLessThan(Date().timeIntervalSince(started), 0.9,
                          "returns without sitting out the pending head start")
    }

    /// URLSession's default is 60 seconds of silence per attempt.
    func testCoverRequestsGiveUpOnSilenceAfterTenSeconds() async {
        var timeout: TimeInterval = 0
        StubURLProtocol.respond = { _, request in
            timeout = request.timeoutInterval
            return self.ok(request)
        }

        _ = await fetch()

        XCTAssertEqual(timeout, 10)
    }

    // MARK: - Fixture

    /// A real 2x2 PNG, so `UIImage(data:)` genuinely decodes rather than being
    /// handed something that only looks like image bytes.
    private static let pngBytes: Data = {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: format)
            .image { context in
                UIColor.systemPink.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
            }
        return image.pngData()!
    }()
}
