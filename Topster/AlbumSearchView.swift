//
//  AlbumSearchView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/25/23.
//

import Foundation
import SwiftUI
import os

/// One line per finished search saying what the ranking hint actually did.
/// Read on a simulator with:
///   xcrun simctl spawn <udid> log show --last 5m --predicate 'subsystem == "com.austinlavalley.Topster"'
private let searchLog = Logger(subsystem: "com.austinlavalley.Topster", category: "search-ranking")



/// Identity for a search run. Bumping `nonce` re-runs the task with the same text,
/// which is how the Search button forces a retry.
private struct SearchRequest: Equatable {
    let text: String
    let nonce: Int
}


struct AlbumSearchView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    @State private var searchResults: [Album] = []
    @State private var searchText: String = ""
    @State private var searchError: String?
    @State private var searchNotice: String?

    /// Which of the current results were backfilled from Deezer discovery
    /// rather than returned by Last.fm's search. Only feeds the albumPlaced
    /// analytics event, so the ranking work can be graded by real taps.
    @State private var backfilledIDs: Set<UUID> = []

    /// One search-sheet visit's story, for the searchAbandoned event: how many
    /// searches settled, and whether any of them ended in a placement.
    @State private var searchesThisVisit = 0
    @State private var placedThisVisit = false
    @State private var isSearching = false
    @State private var searchNonce = 0
    
    @FocusState private var isSearchFocused: Bool
    
    
    private var threeColumnGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack {
                
                HStack {
                    SearchHeaderView()
                    Spacer()
                    if ((vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ _ in })) != nil) {
                        Button {
                            withAnimation {
                                vm.removeAlbumFromGrid(at: vm.selectedGridID ?? 0)
                            }
                        } label: {
                            Label("Remove", systemImage: "").foregroundStyle(.red)
                        }

                    }
                }
                
                Group {
                    HStack {
                        // The view said "Search" four times: title, placeholder,
                        // button, and the keyboard action. The field searches as you
                        // type now, so the button was doing nothing the typing did
                        // not already do. It comes back only as a retry when a search
                        // actually fails.
                        TextField("Album or artist", text: $searchText)
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)
                            .accessibilityIdentifier("album-search-field")
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()

                                    Button("Done") {
                                        isSearchFocused = false
                                    }
                                }
                            }

                        if isSearching {
                            ProgressView()
                        } else if searchError != nil {
                            Button("Try again") {
                                isSearchFocused = false
                                searchNonce += 1
                            }
                            .accessibilityIdentifier("retry-search")
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }.padding(.vertical, ((vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ _ in })) != nil) ? 12 : 0)
                
                if let searchError {
                    Text(searchError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    Spacer()
                } else {
                    if let searchNotice {
                        Text(searchNotice)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                            .accessibilityIdentifier("search-notice")
                    }
                    ScrollView {
                        LazyVGrid(columns: threeColumnGrid) {
                            // Identified by Album.id. Keying on \.name collided constantly,
                            // 49 of 50 results for "greatest hits" share a name, and duplicate
                            // ForEach ids make SwiftUI draw the wrong cell or none at all.
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, result in
                                SearchAlbumSquare(album: result, onPlace: {
                                    placedThisVisit = true
                                    Analytics.track(.albumPlaced(position: index + 1,
                                                                 backfilled: backfilledIDs.contains(result.id)))
                                })
                                    .frame(width: UIScreen.main.bounds.width/3.33333, height: UIScreen.main.bounds.width/3.33333)
                            }
                        }
                    }
                }
                
            }.padding()
                .padding(.vertical)
        }
        // Replaces an onChange that fired a full request per keystroke with no
        // cancellation, so a slow reply for "t" could land last and overwrite the
        // results for the finished title. Changing the id cancels the running task.
        .task(id: SearchRequest(text: searchText, nonce: searchNonce)) {
            await runSearch()
        }

        
        .onAppear {
            isSearchFocused = true
            searchesThisVisit = 0
            placedThisVisit = false
            // Handshakes happen while the user types; see warmConnections().
            Networker().warmConnections()
        }
        .onDisappear {
            if !placedThisVisit && searchesThisVisit > 0 {
                Analytics.track(.searchAbandoned(searches: searchesThisVisit))
            }
        }
    }
    
    
    
    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            searchNotice = nil
            return
        }

        // Wait for typing to settle. Another keystroke cancels this task during the
        // sleep, so no request is ever sent for a half-typed album name.
        do {
            try await Task.sleep(nanoseconds: 350_000_000)
        } catch {
            return
        }

        isSearching = true
        defer { isSearching = false }

        // The ranking hint fires alongside the Last.fm search, not after it, so by
        // the time results arrive it is usually already here. `SearchRanking.value`
        // caps how long it may keep the results waiting when it is not, and a hint
        // that fails or misses the window degrades to plain Last.fm order.
        let hintTask = Task { try? await Networker().deezerRanking(query: query) }
        defer { hintTask.cancel() }

        do {
            let results = try await Networker().searchAlbums(query: query)

            guard !Task.isCancelled else { return }

            // Last.fm returns a lot of albums it has no art for, and a result grid
            // that is mostly blank squares is worse than a shorter one. They are
            // still reachable on the grid itself, just not offered here.
            let withArt = results.filter { album in album.coverURL != nil }

            let hintStart = Date()
            let hint = await SearchRanking.value(of: hintTask)
            let hintMs = Int(Date().timeIntervalSince(hintStart) * 1000)

            guard !Task.isCancelled else { return }

            let ranked = SearchRanking.rank(withArt, hint: hint ?? [])
            let outcome = await SearchResolver.shared.resolveHead(ranked)

            guard !Task.isCancelled else { return }

            let final = SearchRanking.assemble(outcome.scored,
                                               overflow: ranked.overflow, tail: ranked.tail)

            let topTen = { (albums: [Album]) in
                albums.prefix(10).map { a in "\(a.name)/\(a.artist)" }.joined(separator: " | ")
            }
            searchLog.notice("""
                search "\(query, privacy: .public)": lastfm \(results.count) (\(withArt.count) with art), \
                hint \(hint.map { h in "\(h.count) entries" } ?? "nil", privacy: .public) \
                after \(hintMs) ms wait, head \(ranked.head.count)+\(ranked.missing.count) candidates, \
                \(outcome.cacheHits) cached, \(outcome.scored.count) scored\
                \(outcome.throttled ? ", THROTTLED" : "", privacy: .public)
                """)
            searchLog.notice("before: \(topTen(withArt), privacy: .public)")
            searchLog.notice("after:  \(topTen(final), privacy: .public)")

            searchResults = final
            backfilledIDs = Set(final.map { a in a.id })
                .subtracting(withArt.map { a in a.id })
            // Same voice as the rate-limit error, but this one is a note, not a
            // failure: results are showing, just without popularity ranking.
            searchNotice = outcome.throttled
                ? "Too many searches at once. Results are unranked for a minute."
                : nil
            searchError = final.isEmpty ? "No albums with cover art found for \"\(query)\"." : nil

            searchesThisVisit += 1
            Analytics.track(.searchSettled(results: final.count,
                                           backfills: backfilledIDs.count,
                                           hintArrived: hint != nil,
                                           cacheHits: outcome.cacheHits,
                                           throttled: outcome.throttled))
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            searchResults = []
            searchError = error.localizedDescription
        }
    }
}


// ALBUMSQUARE THAT DISPLAYS SEARCH VIEW
struct SearchAlbumSquare: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    let album: Album
    /// Analytics live with the parent, which knows this square's position and
    /// provenance; the square only reports that its moment happened.
    let onPlace: () -> Void

    var body: some View {
        // Same loader as the grid and the export. Beyond consistency, a cover fetched
        // here is already local by the time the album is placed, so it appears on the
        // grid immediately rather than being fetched a second time.
        InternetImage(url: album.coverURL?.absoluteString ?? "",
                      showsProgressWhileLoading: true) { image in
            image.resizable()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onPlace()
            vm.addAlbumToGrid(album: album, at: vm.selectedGridID ?? 0)
            vm.hideSearchSheet()
        }
        // Lets UI tests read the actual result order instead of eyeballing
        // screenshots. The backlog wants identifiers for a search smoke test
        // anyway; this is the first of them.
        .accessibilityIdentifier("search-result")
        .accessibilityLabel("\(album.name), \(album.artist)")
    }
}



struct SearchHeaderView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Add album").font(.title)
                
                if ((vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ _ in })) != nil) {
                    Text(vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ alb in
                        alb.name
                    }) ?? "Couldn't fetch album name").font(.subheadline).italic().foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}





struct AlbumSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumSearchView()
            .environmentObject(FortyScrollGridViewModel())
    }
}
