//
//  SearchRankingTests.swift
//  TopsterTests
//

import XCTest
@testable import Topster

final class SearchRankingTests: XCTestCase {

    private func album(_ name: String, by artist: String) -> Album {
        Album(name: name, artist: artist, url: "", image: [], streamable: "0", mbid: "")
    }

    private func hint(_ entries: (artist: String, title: String)...) -> [DeezerAlbum] {
        entries.map { entry in DeezerAlbum(title: entry.title,
                                           artist: DeezerArtist(name: entry.artist)) }
    }


    // MARK: - Ordering

    /// The whole point: albums Deezer knows float to the top in Deezer's order,
    /// even when Last.fm ranked them below albums Deezer has never heard of.
    func testMatchedAlbumsFloatInHintOrder() {
        let results = [album("Blue", by: "Chezile"),
                       album("Blue", by: "Joni Mitchell"),
                       album("Blue", by: "NewDad"),
                       album("Blue & Lonesome", by: "The Rolling Stones")]

        let ranked = SearchRanking.rerank(results, hint: hint(
            ("Joni Mitchell", "Blue"),
            ("The Rolling Stones", "Blue & Lonesome")))

        XCTAssertEqual(ranked.map { a in a.artist },
                       ["Joni Mitchell", "The Rolling Stones", "Chezile", "NewDad"])
    }

    func testUnmatchedAlbumsKeepTheirRelativeOrder() {
        let results = [album("Blue", by: "A"), album("Blue", by: "B"),
                       album("Blue", by: "C"), album("Blue", by: "D")]

        let ranked = SearchRanking.rerank(results, hint: hint(("C", "Blue")))

        XCTAssertEqual(ranked.map { a in a.artist }, ["C", "A", "B", "D"])
    }

    func testEmptyHintChangesNothing() {
        let results = [album("Blue", by: "Chezile"), album("Blue", by: "Joni Mitchell")]

        let ranked = SearchRanking.rerank(results, hint: [])

        XCTAssertEqual(ranked.map { a in a.artist }, ["Chezile", "Joni Mitchell"])
    }


    // MARK: - Matching across the two services

    /// The services disagree on case, diacritics, punctuation, and "&" for the
    /// same album. None of that should break a match.
    func testCosmeticDifferencesStillMatch() {
        let results = [album("Blue", by: "Nobody"),
                       album("Ágætis byrjun", by: "Sigur Rós"),
                       album("Bookends", by: "Simon & Garfunkel")]

        let ranked = SearchRanking.rerank(results, hint: hint(
            ("Simon and Garfunkel", "Bookends"),
            ("Sigur Ros", "Agaetis Byrjun")))

        XCTAssertEqual(ranked.map { a in a.artist },
                       ["Simon & Garfunkel", "Sigur Rós", "Nobody"])
    }

    /// Edition suffixes differ constantly: Deezer's "Blue (Expanded Version)"
    /// must still rank Last.fm's plain "Blue".
    func testParentheticalEditionsMatchLoosely() {
        let results = [album("Blue", by: "Chezile"), album("Blue", by: "Simply Red")]

        let ranked = SearchRanking.rerank(results,
                                          hint: hint(("Simply Red", "Blue (Expanded Version)")))

        XCTAssertEqual(ranked.first?.artist, "Simply Red")
    }

    /// Weezer's self-titled albums differ *only* in their parenthetical, so the
    /// loose match must not be consulted while an exact one exists. If it were,
    /// both would collapse onto the first hint entry and keep Last.fm's order.
    func testExactTitleBeatsLooseWhenParentheticalsAreTheOnlyDifference() {
        let results = [album("Weezer (Blue Album)", by: "Weezer"),
                       album("Weezer (Green Album)", by: "Weezer")]

        let ranked = SearchRanking.rerank(results, hint: hint(
            ("Weezer", "Weezer (Green Album)"),
            ("Weezer", "Weezer (Blue Album)")))

        XCTAssertEqual(ranked.map { a in a.name },
                       ["Weezer (Green Album)", "Weezer (Blue Album)"])
    }

    /// A different artist's album with the same title must not inherit the rank.
    func testSameTitleDifferentArtistDoesNotMatch() {
        let results = [album("Blue", by: "Kaneki")]

        let ranked = SearchRanking.rerank(results, hint: hint(("Joni Mitchell", "Blue")))

        XCTAssertEqual(ranked.map { a in a.artist }, ["Kaneki"],
                       "no crash, no reorder, Kaneki keeps its Last.fm position")
    }


    // MARK: - Backfill: holes in Last.fm's list

    /// "Blue & Lonesome" is Deezer's #2 for "blue" but absent from all 100 of
    /// Last.fm's results. It must be reported as missing, with its rank, so the
    /// caller can fetch it.
    func testHintEntriesAbsentFromResultsAreReportedAsMissing() {
        let results = [album("Blue", by: "Joni Mitchell"), album("Blue", by: "Chezile")]

        let ranked = SearchRanking.rank(results, hint: hint(
            ("Joni Mitchell", "Blue"),
            ("The Rolling Stones", "Blue & Lonesome")))

        XCTAssertEqual(ranked.missing.count, 1)
        XCTAssertEqual(ranked.missing.first?.entry.artist.name, "The Rolling Stones")
        XCTAssertEqual(ranked.missing.first?.rank, 1)
    }

    /// Only the top of Deezer's list is worth an extra request per entry. A
    /// 15-entry hint matching nothing must report exactly backfillDepth holes.
    func testEntriesBeyondTheBackfillDepthAreNotReported() {
        let results = [album("Blue", by: "Somebody")]
        let deepHint = (0..<15).map { i in
            DeezerAlbum(title: "Blue \(i)", artist: DeezerArtist(name: "Artist \(i)"))
        }

        let ranked = SearchRanking.rank(results, hint: deepHint)

        XCTAssertEqual(ranked.missing.count, SearchRanking.backfillDepth)
        XCTAssertTrue(ranked.missing.allSatisfy { entry in entry.rank < SearchRanking.backfillDepth })
    }

    /// An album matched loosely is present, not missing; fetching it again would
    /// duplicate it.
    func testLooselyMatchedEntriesAreNotMissing() {
        let results = [album("Blue", by: "Simply Red")]

        let ranked = SearchRanking.rank(results, hint: hint(("Simply Red", "Blue (Expanded Version)")))

        XCTAssertTrue(ranked.missing.isEmpty)
    }

    /// A search Last.fm whiffs entirely can still be rescued by the hint.
    func testEmptyResultsWithAHintReportEveryTopEntryMissing() {
        let ranked = SearchRanking.rank([], hint: hint(("A", "One"), ("B", "Two")))

        XCTAssertEqual(ranked.missing.count, 2)
        XCTAssertTrue(ranked.albums.isEmpty)
    }

    /// Matches beyond the head cap are not worth a lookup each; they keep
    /// Deezer's order between the head and the unmatched tail.
    func testMatchesBeyondTheHeadCapOverflowInOrder() {
        let names = (0..<15).map { i in "Album \(i)" }
        let results = names.map { name in album(name, by: "Artist") }
        let fullHint = names.map { name in
            DeezerAlbum(title: name, artist: DeezerArtist(name: "Artist"))
        }

        let ranked = SearchRanking.rank(results, hint: fullHint)

        XCTAssertEqual(ranked.head.count, SearchRanking.matchedHeadCap)
        XCTAssertEqual(ranked.overflow.map { a in a.name },
                       Array(names.dropFirst(SearchRanking.matchedHeadCap)))
        XCTAssertTrue(ranked.tail.isEmpty)
    }


    // MARK: - Assembling by listeners

    private func scored(_ rank: Int, _ listeners: Int, _ name: String,
                        by artist: String) -> SearchRanking.Scored {
        SearchRanking.Scored(rank: rank, listeners: listeners,
                             album: album(name, by: artist))
    }

    /// The ranking axis: Last.fm listeners, not Deezer's order. Deezer rank 0
    /// with few listeners must lose to Deezer rank 2 with many.
    func testAssembleSortsTheHeadByListeners() {
        let final = SearchRanking.assemble(
            [scored(0, 47_585, "LØVE", by: "Julien Doré"),
             scored(2, 1_066_100, "Love", by: "The Beatles"),
             scored(1, 420_281, "Love", by: "The Cult")],
            overflow: [album("Love", by: "Overflow Artist")],
            tail: [album("Love", by: "Tail Artist")])

        XCTAssertEqual(final.map { a in a.artist },
                       ["The Beatles", "The Cult", "Julien Doré",
                        "Overflow Artist", "Tail Artist"])
    }

    /// A failed lookup carries 0 listeners: those entries settle at the bottom
    /// of the head in Deezer order, the pre-listeners behaviour, rather than
    /// vanishing or jumping around.
    func testAssembleFailedLookupsFallBackToDeezerOrder() {
        let final = SearchRanking.assemble(
            [scored(3, 0, "Blue", by: "B"),
             scored(1, 0, "Blue", by: "A"),
             scored(0, 500, "Blue", by: "Ranked")],
            overflow: [], tail: [])

        XCTAssertEqual(final.map { a in a.artist }, ["Ranked", "A", "B"])
    }

    /// "Forever Changes" three times as remasters collapses onto the most
    /// listened edition; the others drop to the very end, still reachable.
    func testAssembleCollapsesEditionNoiseOntoTheMostListened() {
        let final = SearchRanking.assemble(
            [scored(0, 236_490, "Forever Changes", by: "Love"),
             scored(1, 182_992, "Forever Changes (2015 Remaster)", by: "Love"),
             scored(2, 1_000_000, "Love", by: "The Beatles")],
            overflow: [], tail: [album("Love", by: "Tail Artist")])

        XCTAssertEqual(final.map { a in a.name },
                       ["Love", "Forever Changes", "Love",
                        "Forever Changes (2015 Remaster)"])
        XCTAssertEqual(final.last?.name, "Forever Changes (2015 Remaster)",
                       "the losing edition belongs after the tail")
    }

    /// Weezer's parentheticals *identify* the albums, so they must never
    /// collapse into each other the way edition noise does.
    func testAssembleKeepsIdentifyingParentheticalsApart() {
        let final = SearchRanking.assemble(
            [scored(0, 900_000, "Weezer (Blue Album)", by: "Weezer"),
             scored(1, 700_000, "Weezer (Green Album)", by: "Weezer")],
            overflow: [], tail: [])

        XCTAssertEqual(final.count, 2)
        XCTAssertEqual(final.map { a in a.name },
                       ["Weezer (Blue Album)", "Weezer (Green Album)"])
    }

    /// A backfill can resolve to an edition of an album the head already holds;
    /// the duplicate collapses instead of showing twice.
    func testAssembleCollapsesABackfillDuplicatingAMatchedAlbum() {
        let final = SearchRanking.assemble(
            [scored(5, 22_839, "Blue", by: "Simply Red"),
             scored(0, 44_825, "Blue (Expanded Version)", by: "Simply Red")],
            overflow: [], tail: [])

        XCTAssertEqual(final.first?.name, "Blue (Expanded Version)",
                       "the more listened edition wins the slot")
        XCTAssertEqual(final.count, 2)
        XCTAssertEqual(final.last?.name, "Blue")
    }


    // MARK: - The resolver: cache, gate, and failure paths

    private actor CallCounter {
        private(set) var count = 0
        func bump() { count += 1 }
    }

    private func art() -> [AlbumImage] {
        [AlbumImage(text: "https://example.com/300.png", size: "extralarge")]
    }

    private func ranked(matched: [(String, String)],
                        missing: [(String, String)]) -> SearchRanking.Ranked {
        SearchRanking.Ranked(
            head: matched.enumerated().map { i, pair in
                SearchRanking.Backfill(rank: i, album: album(pair.1, by: pair.0))
            },
            overflow: [], tail: [],
            missing: missing.enumerated().map { i, pair in
                SearchRanking.MissingEntry(rank: matched.count + i,
                                           entry: DeezerAlbum(title: pair.1,
                                                              artist: DeezerArtist(name: pair.0)))
            })
    }

    @MainActor
    func testResolverScoresMatchesAndBackfillsFromLookups() async {
        let resolver = SearchResolver(
            lookup: { artist, title in
                AlbumInfo(album: Album(name: title, artist: artist, url: "",
                                       image: [AlbumImage(text: "https://example.com/300.png",
                                                          size: "extralarge")],
                                       streamable: "0", mbid: ""),
                          listeners: artist == "Coldplay" ? 4_926_801 : 100)
            },
            gate: SearchRanking.ThrottleGate(cooldown: 60))

        let outcome = await resolver.resolveHead(ranked(
            matched: [("Cold", "Year Of The Spider")],
            missing: [("Coldplay", "Parachutes")]))

        XCTAssertEqual(outcome.scored.count, 2)
        XCTAssertFalse(outcome.throttled)
        XCTAssertEqual(outcome.scored.first { s in s.album.artist == "Coldplay" }?.listeners,
                       4_926_801)
    }

    /// The second resolve of the same head must come from cache, not the
    /// network. This is what keeps refined queries cheap for Last.fm.
    @MainActor
    func testResolverServesRepeatsFromCache() async {
        let calls = CallCounter()
        let images = art()
        let resolver = SearchResolver(
            lookup: { artist, title in
                await calls.bump()
                return AlbumInfo(album: Album(name: title, artist: artist, url: "",
                                              image: images, streamable: "0", mbid: ""),
                                 listeners: 5)
            },
            gate: SearchRanking.ThrottleGate(cooldown: 60))
        let head = ranked(matched: [("A", "One"), ("B", "Two")], missing: [("C", "Three")])

        _ = await resolver.resolveHead(head)
        let firstCalls = await calls.count
        let second = await resolver.resolveHead(head)
        let totalCalls = await calls.count

        XCTAssertEqual(firstCalls, 3)
        XCTAssertEqual(totalCalls, 3, "the repeat must not touch the network")
        XCTAssertEqual(second.cacheHits, 3)
        XCTAssertEqual(second.scored.count, 3)
    }

    /// Error 29 trips the gate: this search reports throttled, and the next
    /// makes no lookups at all while keeping matched results visible.
    @MainActor
    func testResolverTripsTheGateOn29AndStopsCalling() async {
        let calls = CallCounter()
        let resolver = SearchResolver(
            lookup: { _, _ in
                await calls.bump()
                throw NetworkError.api(code: 29, message: "Rate limit exceeded")
            },
            gate: SearchRanking.ThrottleGate(cooldown: 3600))
        let head = ranked(matched: [("A", "One")], missing: [("B", "Two")])

        let first = await resolver.resolveHead(head)
        let callsAfterFirst = await calls.count
        let second = await resolver.resolveHead(head)
        let totalCalls = await calls.count

        XCTAssertTrue(first.throttled)
        XCTAssertTrue(second.throttled)
        XCTAssertEqual(totalCalls, callsAfterFirst,
                       "a closed gate must not make lookups")
        XCTAssertEqual(second.scored.count, 1, "the matched album stays, unranked")
        XCTAssertEqual(second.scored.first?.listeners, 0)
    }

    /// An ordinary failure is not a throttle: the matched album stays at 0
    /// listeners, the backfill vanishes, and the gate stays open.
    @MainActor
    func testResolverKeepsMatchedAlbumsWhenLookupsFail() async {
        let resolver = SearchResolver(
            lookup: { _, _ in throw NetworkError.http(status: 500) },
            gate: SearchRanking.ThrottleGate(cooldown: 60))

        let outcome = await resolver.resolveHead(ranked(
            matched: [("A", "One")], missing: [("B", "Two")]))

        XCTAssertFalse(outcome.throttled)
        XCTAssertEqual(outcome.scored.map { s in s.album.artist }, ["A"])
        XCTAssertEqual(outcome.scored.first?.listeners, 0)
    }

    /// Lookups slower than the budget are abandoned promptly, and the matched
    /// albums still ship, unranked.
    @MainActor
    func testResolverAbandonsLookupsThatMissTheBudget() async {
        let resolver = SearchResolver(
            lookup: { artist, title in
                try await Task.sleep(nanoseconds: 10_000_000_000)
                return AlbumInfo(album: Album(name: title, artist: artist, url: "",
                                              image: [], streamable: "0", mbid: ""),
                                 listeners: 5)
            },
            gate: SearchRanking.ThrottleGate(cooldown: 60),
            budgetNanoseconds: 50_000_000)

        let start = Date()
        let outcome = await resolver.resolveHead(ranked(matched: [("A", "One")], missing: []))
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 2.0, "the budget must cap the wait")
        XCTAssertEqual(outcome.scored.map { s in s.album.artist }, ["A"])
        XCTAssertEqual(outcome.scored.first?.listeners, 0)
        XCTAssertFalse(outcome.throttled)
    }


    // MARK: - The throttle gate

    /// One error 29 closes the gate for the cooldown; time reopens it. Tested
    /// with a zero cooldown so "time passing" is immediate.
    func testThrottleGateClosesOnTripAndReopensAfterCooldown() async {
        let gate = SearchRanking.ThrottleGate(cooldown: 3600)
        let openIsDefault = await gate.isOpen
        XCTAssertTrue(openIsDefault)

        await gate.trip()
        let closedAfterTrip = await gate.isOpen
        XCTAssertFalse(closedAfterTrip)

        let expired = SearchRanking.ThrottleGate(cooldown: -1)
        await expired.trip()
        let reopened = await expired.isOpen
        XCTAssertTrue(reopened, "an elapsed cooldown must reopen the gate")
    }


    // MARK: - The grace window

    func testAHintThatArrivedInTimeIsUsed() async {
        let task = Task<Int?, Never> { 42 }

        let value = await SearchRanking.value(of: task, within: 2_000_000_000)

        XCTAssertEqual(value, 42)
    }

    /// A hint slower than the window comes back nil, and comes back *promptly*.
    /// The elapsed assertion is what fails if awaiting the task blocks past the
    /// window, which is exactly the bug the cancellation in `value(of:within:)`
    /// exists to prevent.
    func testAHintThatMissesTheWindowIsDroppedPromptly() async {
        let task = Task<Int?, Never> {
            do { try await Task.sleep(nanoseconds: 10_000_000_000) } catch { return nil }
            return 42
        }

        let start = Date()
        let value = await SearchRanking.value(of: task, within: 50_000_000)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertNil(value)
        XCTAssertLessThan(elapsed, 2.0, "waiting out the full task defeats the window")
    }
}
