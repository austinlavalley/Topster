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
    

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchText)
                    Button("serach") {
                        searchForArtists()
                    }
                }
                List(searchResults, id: \.name) { result in
                    Text(result.name ?? "n/a")
//                    Text("\(result.name ?? "n/a") - \(result.listeners ?? "0")")
                }
                .navigationBarTitle("Search")
            }
        }
        .onChange(of: searchText) { _ in
            searchForArtists()
        }
    }
    
    
    private func searchForArtists() {
        Networker().searchArtists(query: searchText) { result in
            
            switch result {
            case .success(let returnedArtists):
                self.searchResults = returnedArtists
            case .failure(let error):
                print("Error fetching top artists: \(error)")
            }
        }
    }
}

// MARK: - SearchResults
struct SearchResults: Codable {
    let results: Results
}

// MARK: - Results
struct Results: Codable {
    let opensearchQuery: OpensearchQuery?
    let opensearchTotalResults, opensearchStartIndex, opensearchItemsPerPage: String?
    let artistmatches: Artistmatches
}

// MARK: - Artistmatches
struct Artistmatches: Codable {
    let artist: [Artist]
}

//struct Artist: Codable {
//    let name, listeners, mbid: String?
//    let url: String?
//    let streamable: String?
////    let image: [Image]?
//}

// MARK: - Image
//struct Image: {
//    let text: String
//    let size: String
//}

// MARK: - OpensearchQuery
struct OpensearchQuery: Codable {
    let text, role, searchTerms, startPage: String?
}





struct ArtistSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistSearchView()
    }
}
