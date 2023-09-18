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
                    Button("serach") { search() }
                }
                List(searchResults, id: \.name) { result in
                    Text(result.name ?? "ehe")
                }
                .navigationBarTitle("Search")
            }
        }
        .onChange(of: searchText) { _ in
            search()
        }
    }

    func search() {
        guard let url = URL(string: "https://ws.audioscrobbler.com/2.0/?method=artist.search&artist=\(searchText)&api_key=4a4a5193d0fbc4584f64f7032c91d277&format=json") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let results = try decoder.decode(SearchResults.self, from: data)
//                    print(results.results.artistmatches.artist)
                    DispatchQueue.main.async {
                        self.searchResults = results.results.artistmatches.artist
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
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
