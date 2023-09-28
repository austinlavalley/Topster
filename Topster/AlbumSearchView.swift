//
//  AlbumSearchView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/25/23.
//

import Foundation
import SwiftUI

struct AlbumSearchView: View {
    @State private var searchResults: [Album] = []
    @State private var searchText: String = ""
    
    private var threeColumnGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchText)
                    Button("serach") {
                        searchForArtists()
                    }
                }
                ScrollView {
                    LazyVGrid(columns: threeColumnGrid) {
                        ForEach(searchResults, id: \.name) { result in
                            AsyncImage(url: URL(string: result.image?.first(where: { $0.size == "large" })?.text ?? "")) { image in
                                image
                                    .resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 96, height: 96)
                        }
                    }
                }
                .navigationBarTitle("Search")
            }
            .padding()
        }
        .onChange(of: searchText) { _ in
            searchForArtists()
        }
    }
    
    
    private func searchForArtists() {
        Networker().searchAlbums(query: searchText) { result in
            
            switch result {
            case .success(let returnedArtists):
                self.searchResults = returnedArtists
            case .failure(let error):
                print("Error fetching top artists: \(error)")
            }
        }
    }
}


struct AlbumSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumSearchView()
    }
}
