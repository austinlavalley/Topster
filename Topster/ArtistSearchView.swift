//
//  ArtistSearchView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/14/23.
//

import Foundation
import SwiftUI

struct ArtistSearchView: View {
    @State private var searchResults: [Artist] = []
    @State private var searchText: String = ""
    @State private var searchError: String?
    

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchText)
                }

                if let searchError {
                    Text(searchError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    // Artist names are not unique and the field is optional, so results
                    // are identified by position rather than by name.
                    List(Array(searchResults.enumerated()), id: \.offset) { _, result in
                        HStack {
                            Text(result.name ?? "")
                        }
                    }
                }
            }
            .navigationBarTitle("Search")
            .padding()
        }
        .task(id: searchText) {
            await runSearch()
        }
    }
    
    
    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }

        do {
            try await Task.sleep(nanoseconds: 350_000_000)
        } catch {
            return
        }

        do {
            let results = try await Networker().searchArtists(query: query)

            guard !Task.isCancelled else { return }

            searchResults = results
            searchError = results.isEmpty ? "No artists found for \"\(query)\"." : nil
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            searchResults = []
            searchError = error.localizedDescription
        }
    }
}


struct ArtistSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistSearchView()
    }
}
