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

    static func reset() {
        respond = nil
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1

        guard let respond = Self.respond else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try respond(Self.requestCount, request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
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

    private let url = URL(string: "https://example.com/cover.png")!

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()

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
