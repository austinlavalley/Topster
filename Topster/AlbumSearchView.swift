//
//  AlbumSearchView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/25/23.
//

import Foundation
import SwiftUI


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
                    ScrollView {
                        LazyVGrid(columns: threeColumnGrid) {
                            // Identified by Album.id. Keying on \.name collided constantly,
                            // 49 of 50 results for "greatest hits" share a name, and duplicate
                            // ForEach ids make SwiftUI draw the wrong cell or none at all.
                            ForEach(searchResults) { result in
                                SearchAlbumSquare(album: result)
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
        }
    }
    
    
    
    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
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

        do {
            let results = try await Networker().searchAlbums(query: query)

            guard !Task.isCancelled else { return }

            // Last.fm returns a lot of albums it has no art for, and a result grid
            // that is mostly blank squares is worse than a shorter one. They are
            // still reachable on the grid itself, just not offered here.
            let withArt = results.filter { album in album.coverURL != nil }

            searchResults = withArt
            searchError = withArt.isEmpty ? "No albums with cover art found for \"\(query)\"." : nil
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

    var body: some View {
        Group {
            if let coverURL = album.coverURL {
                AsyncImage(url: coverURL) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else if phase.error != nil {
                        NoCoverPlaceholder(showsLabel: true)
                    } else {
                        ProgressView()
                    }
                }
            } else {
                // Last.fm has no art for this album. Still selectable, since plenty of
                // records people want on a grid have no cover on file.
                NoCoverPlaceholder(showsLabel: true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            vm.addAlbumToGrid(album: album, at: vm.selectedGridID ?? 0)
            vm.hideSearchSheet()
        }
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
