//
//  SearchRanking.swift
//  Topster
//

import Foundation


/// Reorders Last.fm search results by popularity, with Deezer as a discovery aid.
///
/// Last.fm's `album.search` has no sort parameter and returns no popularity data,
/// so a search for "blue" leads with whichever obscure albums are literally titled
/// Blue, and never returns Coldplay for "cold" at all. The division of labour:
///
/// - **Deezer decides only what the search should have found**: its list marks
///   which Last.fm results deserve the head of the list, and its top entries that
///   Last.fm's search missed entirely get fetched from Last.fm by exact name.
///   Deezer's own ordering and fan counts are ignored; both proved French-leaning
///   ("love" put Julien Doré above The Beatles).
/// - **Last.fm supplies everything shown and the ranking number**: every album,
///   every cover, and the `album.getInfo` listener count the head is sorted by.
///
/// Simulated against live data on 27 Aug 2026 before being built: listener
/// ordering was the only variant that got The Beatles, Coldplay, and Pink Floyd
/// to the top of "love", "cold", and "dark" simultaneously.
/// If the hint or the lookups never arrive, results degrade stepwise toward
/// exactly the plain Last.fm order.
enum SearchRanking {

    /// How long the results may wait on the hint after Last.fm has answered.
    ///
    /// The hint request runs alongside the Last.fm search, so this is a cap on the
    /// straggle, not a fixed cost. Measured 27 Aug 2026: Deezer answers in 0.38 to
    /// 0.72 s against Last.fm's 0.10 to 0.34 s. At 300 ms the hint was observed
    /// missing the window ("love" came back nil after 325 ms and that search
    /// silently lost its ranking); 700 ms covers Deezer's whole measured range,
    /// and the trade of wait for relevance is deliberate.
    static let graceWindowNanoseconds: UInt64 = 700_000_000


    // MARK: - Reordering

    /// How deep into Deezer's list to look for albums Last.fm failed to return
    /// at all. Each one found costs an `album.getInfo` call to backfill.
    static let backfillDepth = 10

    /// How many Deezer-matched results join the head. Everything in the head is
    /// resolved through `album.getInfo` for its listener count, so together with
    /// `backfillDepth` this caps extra Last.fm requests per search at 22, before
    /// the session cache removes repeats.
    static let matchedHeadCap = 12

    /// How long the head lookups may keep the results waiting. All of them run
    /// as one parallel burst, so this covers a round trip, not a sum.
    static let resolveBudgetNanoseconds: UInt64 = 800_000_000


    /// An album destined for the head, tied to its Deezer rank.
    struct Backfill {
        let rank: Int
        let album: Album
    }

    /// A hint entry with no counterpart anywhere in Last.fm's results.
    struct MissingEntry {
        let rank: Int
        let entry: DeezerAlbum
    }

    /// A head album with its listener count resolved (0 when the lookup failed,
    /// which sinks it below resolved entries but keeps it in the head).
    struct Scored {
        let rank: Int
        let listeners: Int
        let album: Album
    }

    /// The outcome of matching: head candidates worth a listener lookup, matched
    /// overflow beyond the cap, the unmatched Last.fm tail, and the hint entries
    /// worth backfilling because Last.fm never returned them.
    struct Ranked {
        let head: [Backfill]
        let overflow: [Album]
        let tail: [Album]
        let missing: [MissingEntry]

        /// The order shown if the listener lookups never arrive.
        var albums: [Album] { head.map { entry in entry.album } + overflow + tail }
    }


    static func rerank(_ albums: [Album], hint: [DeezerAlbum]) -> [Album] {
        rank(albums, hint: hint).albums
    }

    static func rank(_ albums: [Album], hint: [DeezerAlbum]) -> Ranked {
        guard !hint.isEmpty else {
            return Ranked(head: [], overflow: [], tail: albums, missing: [])
        }

        // Two rank maps, because parentheticals cut both ways. Stripping them lets
        // "Blue (Expanded Version)" match "Blue", but Weezer's self-titled albums
        // are distinguishable *only* by their parenthetical, so the exact key is
        // consulted first and the stripped key is a fallback.
        var exactRank: [String: Int] = [:]
        var looseRank: [String: Int] = [:]
        for (rank, entry) in hint.enumerated() {
            let exact = key(artist: entry.artist.name, title: entry.title, loose: false)
            let loose = key(artist: entry.artist.name, title: entry.title, loose: true)
            if exactRank[exact] == nil { exactRank[exact] = rank }
            if looseRank[loose] == nil { looseRank[loose] = rank }
        }

        func rank(of album: Album) -> Int? {
            exactRank[key(artist: album.artist, title: album.name, loose: false)]
                ?? looseRank[key(artist: album.artist, title: album.name, loose: true)]
        }

        let indexed = Array(albums.enumerated())
        let matched = indexed
            .compactMap { pair in rank(of: pair.element).map { (rank: $0, pair: pair) } }
            .sorted { ($0.rank, $0.pair.offset) < ($1.rank, $1.pair.offset) }

        let matchedOffsets = Set(matched.map { entry in entry.pair.offset })
        let unmatched = indexed.filter { pair in !matchedOffsets.contains(pair.offset) }

        // Deezer's top entries that no result matched are the albums the user
        // calls obvious and Last.fm's search never surfaced. They can be fetched
        // by exact name and inserted where their rank says they belong.
        let assignedRanks = Set(matched.map { entry in entry.rank })
        let missing = hint.prefix(backfillDepth).enumerated()
            .filter { pair in !assignedRanks.contains(pair.offset) }
            .map { pair in MissingEntry(rank: pair.offset, entry: pair.element) }

        let capped = matched.prefix(matchedHeadCap)
        let overflow = matched.dropFirst(matchedHeadCap)

        return Ranked(head: capped.map { entry in Backfill(rank: entry.rank, album: entry.pair.element) },
                      overflow: overflow.map { entry in entry.pair.element },
                      tail: unmatched.map { pair in pair.element },
                      missing: missing)
    }

    /// The final order: head sorted by listeners, then matched overflow in Deezer
    /// order, then the unmatched tail in Last.fm order. Duplicate editions in the
    /// head ("Forever Changes" three times as remasters) collapse onto the most
    /// listened one; the losers drop to the very end rather than vanishing.
    /// Entries whose lookup failed carry 0 listeners and settle at the bottom of
    /// the head in Deezer order, which is the pre-listeners behaviour.
    static func assemble(_ scored: [Scored], overflow: [Album], tail: [Album]) -> [Album] {
        let ordered = scored.sorted { a, b in
            a.listeners != b.listeners ? a.listeners > b.listeners : a.rank < b.rank
        }

        var seen = Set<String>()
        var head: [Album] = []
        var editions: [Album] = []
        for entry in ordered {
            let key = dedupeKey(artist: entry.album.artist, title: entry.album.name)
            if seen.insert(key).inserted {
                head.append(entry.album)
            } else {
                editions.append(entry.album)
            }
        }

        return head + overflow + tail + editions
    }

    /// Titles that differ only by edition noise share a key, so remasters and
    /// deluxe versions collapse. A parenthetical that *identifies* the album,
    /// "Weezer (Blue Album)" against "Weezer (Green Album)", is not noise and
    /// must keep the two apart, so only recognised edition words are stripped.
    static func dedupeKey(artist: String, title: String) -> String {
        let stripped = title.replacingOccurrences(
            of: #"(?i)[\(\[][^\)\]]*(remaster|deluxe|edition|version|expanded|anniversary|reissue|bonus|mono|stereo|explicit|clean|advance|domestic|international)[^\)\]]*[\)\]]"#,
            with: " ",
            options: .regularExpression)
        return key(artist: artist, title: stripped, loose: false)
    }

    /// One key per (artist, title), normalised until the two services agree.
    /// Case, diacritics ("Sigur Rós" / "Sigur Ros"), punctuation, and "&" versus
    /// "and" all vary between them for the same album.
    static func key(artist: String, title: String, loose: Bool) -> String {
        normalize(artist, loose: false) + "|" + normalize(title, loose: loose)
    }

    /// Ligatures and letters that diacritic folding leaves alone. Folding turns
    /// "ó" into "o" but "æ" is its own letter, not an accented one, so "Ágætis
    /// byrjun" failed to match Deezer's "Agaetis Byrjun" until these were mapped
    /// by hand. Caught by the first test run.
    private static let letterSubstitutions = [
        ("æ", "ae"), ("œ", "oe"), ("ø", "o"), ("ß", "ss"),
        ("ð", "d"), ("þ", "th"), ("đ", "d"), ("ł", "l")
    ]

    static func normalize(_ text: String, loose: Bool) -> String {
        var t = text.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .replacingOccurrences(of: "&", with: " and ")

        for (letter, ascii) in Self.letterSubstitutions {
            t = t.replacingOccurrences(of: letter, with: ascii)
        }

        if loose {
            t = t.replacingOccurrences(of: #"\([^)]*\)|\[[^\]]*\]"#,
                                       with: " ",
                                       options: .regularExpression)
        }

        let kept = t.map { ch in ch.isLetter || ch.isNumber ? ch : " " }
        return String(kept).split(separator: " ").joined(separator: " ")
    }


    // MARK: - Backing off when Last.fm says stop

    /// Trips when Last.fm answers a lookup with error 29 (rate limited) and
    /// holds all listener lookups off for a cooldown, during which searches
    /// degrade to Deezer-order heads instead of hammering a throttled API.
    /// Probed 27 Aug 2026: ~200 calls at 5/s for a minute drew no 29s, so this
    /// gate is insurance, not an expected code path.
    actor ThrottleGate {
        static let shared = ThrottleGate(cooldown: 60)

        private let cooldown: TimeInterval
        private var trippedAt: Date?

        init(cooldown: TimeInterval) {
            self.cooldown = cooldown
        }

        func trip() {
            trippedAt = Date()
        }

        var isOpen: Bool {
            guard let trippedAt else { return true }
            return Date().timeIntervalSince(trippedAt) > cooldown
        }
    }


    // MARK: - Waiting on the hint (and lookups)

    /// The task's value, or nil once the grace window runs out.
    ///
    /// Awaiting a `Task<_, Never>` is not a cancellation point, so racing it
    /// against a timer is not enough: the group would still sit until the request
    /// finished. Cancelling the task itself is what unblocks the losing child,
    /// because `URLSession` bails out promptly when its task is cancelled.
    static func value<T: Sendable>(of task: Task<T?, Never>,
                                   within nanoseconds: UInt64 = graceWindowNanoseconds) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await task.value }
            group.addTask {
                try? await Task.sleep(nanoseconds: nanoseconds)
                return nil
            }

            let first = await group.next() ?? nil
            task.cancel()
            group.cancelAll()
            return first
        }
    }
}


/// Resolves a ranked head into scored albums: getInfo listener counts for every
/// candidate, backfill albums for the holes, a session cache in front of the
/// network, and the throttle gate around all of it.
///
/// This is orchestration, not policy: what to fetch comes from `SearchRanking`,
/// how to order comes from `assemble`. It lives outside the view so the cache,
/// the gate, and the failure paths can be exercised by unit tests, with the
/// network call injected.
@MainActor
final class SearchResolver {

    typealias Lookup = @Sendable (_ artist: String, _ title: String) async throws -> AlbumInfo

    static let shared = SearchResolver()

    struct Outcome {
        let scored: [SearchRanking.Scored]
        let cacheHits: Int
        /// True when the throttle gate held lookups back (or closed during
        /// them), meaning this search shipped without listener ranking.
        let throttled: Bool
    }

    private struct Resolution {
        let rank: Int
        let cacheKey: String
        let matched: Album?
        let info: AlbumInfo
    }

    private var cache: [String: AlbumInfo] = [:]
    private let lookup: Lookup
    private let gate: SearchRanking.ThrottleGate
    private let budgetNanoseconds: UInt64

    init(lookup: @escaping Lookup = { artist, title in
             try await Networker().albumInfo(artist: artist, album: title)
         },
         gate: SearchRanking.ThrottleGate = .shared,
         budgetNanoseconds: UInt64 = SearchRanking.resolveBudgetNanoseconds) {
        self.lookup = lookup
        self.gate = gate
        self.budgetNanoseconds = budgetNanoseconds
    }

    func resolveHead(_ ranked: SearchRanking.Ranked) async -> Outcome {
        var scored: [SearchRanking.Scored] = []
        var pending: [(rank: Int, artist: String, title: String, matched: Album?)] = []

        for entry in ranked.head {
            let key = SearchRanking.key(artist: entry.album.artist,
                                        title: entry.album.name, loose: false)
            if let cached = cache[key] {
                scored.append(.init(rank: entry.rank, listeners: cached.listeners,
                                    album: entry.album))
            } else {
                pending.append((entry.rank, entry.album.artist, entry.album.name, entry.album))
            }
        }
        for item in ranked.missing {
            let key = SearchRanking.key(artist: item.entry.artist.name,
                                        title: item.entry.title, loose: false)
            if let cached = cache[key] {
                if cached.album.coverURL != nil {
                    scored.append(.init(rank: item.rank, listeners: cached.listeners,
                                        album: cached.album))
                }
            } else {
                pending.append((item.rank, item.entry.artist.name, item.entry.title, nil))
            }
        }

        let cacheHits = scored.count

        // Rate limited within the cooldown: no lookups. Matched results stay,
        // unranked, so the search degrades rather than piling onto a throttled
        // API. Backfills simply don't happen this minute.
        guard await gate.isOpen else {
            for item in pending where item.matched != nil {
                scored.append(.init(rank: item.rank, listeners: 0, album: item.matched!))
            }
            return Outcome(scored: scored, cacheHits: cacheHits, throttled: true)
        }

        if !pending.isEmpty {
            let lookup = self.lookup
            let gate = self.gate
            let work = pending
            // Detached, or it inherits this class's MainActor isolation and the
            // collection loop competes with SwiftUI for the main thread, which
            // was observed blowing the whole budget while the UI was busy.
            let resolveTask = Task.detached { () -> [Resolution]? in
                await withTaskGroup(of: Resolution?.self) { group in
                    for item in work {
                        group.addTask {
                            let info: AlbumInfo
                            do {
                                info = try await lookup(item.artist, item.title)
                            } catch NetworkError.api(29, _) {
                                await gate.trip()
                                return nil
                            } catch {
                                return nil
                            }
                            let key = SearchRanking.key(artist: item.artist,
                                                        title: item.title, loose: false)
                            return Resolution(rank: item.rank, cacheKey: key,
                                              matched: item.matched, info: info)
                        }
                    }

                    var found: [Resolution] = []
                    for await result in group {
                        if let result { found.append(result) }
                    }
                    return found
                }
            }
            let resolutions = await SearchRanking.value(of: resolveTask,
                                                        within: budgetNanoseconds) ?? []

            var resolvedRanks = Set<Int>()
            for resolution in resolutions {
                cache[resolution.cacheKey] = resolution.info
                resolvedRanks.insert(resolution.rank)

                if let matched = resolution.matched {
                    scored.append(.init(rank: resolution.rank,
                                        listeners: resolution.info.listeners,
                                        album: matched))
                } else if resolution.info.album.coverURL != nil {
                    scored.append(.init(rank: resolution.rank,
                                        listeners: resolution.info.listeners,
                                        album: resolution.info.album))
                }
            }

            // A matched album whose lookup failed or missed the budget is still
            // a real search result; it stays, unranked at 0 listeners. A
            // backfill that failed simply never existed here.
            for item in pending where item.matched != nil && !resolvedRanks.contains(item.rank) {
                scored.append(.init(rank: item.rank, listeners: 0, album: item.matched!))
            }
        }

        let throttled = !(await gate.isOpen)
        return Outcome(scored: scored, cacheHits: cacheHits, throttled: throttled)
    }
}
