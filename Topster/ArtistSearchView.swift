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
                    HStack {
                        Text(result.name ?? "")                        
                    }
                }
                .navigationBarTitle("Search")
            }
            .padding()
        }
        .onChange(of: searchText) {
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




struct ArtistSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistSearchView()
    }
}
