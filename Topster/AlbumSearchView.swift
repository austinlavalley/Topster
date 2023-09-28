//
//  AlbumSearchView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/25/23.
//

import Foundation
import SwiftUI

struct AlbumSearchView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    @State private var searchResults: [Album] = []
    @State private var searchText: String = ""
    
    private var threeColumnGrid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchText)
                    Button("Search") {
                        searchForArtists()
                    }
                }
                ScrollView {
                    LazyVGrid(columns: threeColumnGrid) {
                        ForEach(searchResults, id: \.name) { result in
                            AsyncImage(url: URL(string: result.image?.first(where: { $0.size == "large" })?.text ?? "")) { image in
                                image
                                    .resizable()
                                    .onTapGesture {
                                        print(result.name ?? "No album name")
                                        // need to do something to close this sheet
                                        vm.showSearchSheet = false
                                    }
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 120, height: 120)
                        }
                    }
                }
                .navigationBarTitle("Search")
            }
            .padding()
        }
//        .onChange(of: searchText) { _ in
//            searchForArtists()
//        }
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
            .environmentObject(FortyScrollGridViewModel())
    }
}
