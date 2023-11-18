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
                        searchForAlbums()
                    }
                }
                ScrollView {
                    LazyVGrid(columns: threeColumnGrid) {
                        ForEach(searchResults, id: \.name) { result in
                            SearchAlbumSquare(album: result)
                                .frame(width: UIScreen.main.bounds.width/3.33333, height: UIScreen.main.bounds.width/3.33333)
                        }
                    }
                }
            }
            .padding()
            
            .navigationBarTitle("Search")
            
            .toolbar {
                if ((vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ _ in })) != nil) {
                    Button("remove") {
                        vm.removeAlbumFromGrid(at: vm.selectedGridID ?? 0)
                        vm.hideSearchSheet()
                    }
                }
            }
        }
        .onChange(of: searchText) { _ in
            searchForAlbums()
        }
    }
    
    
    
    private func searchForAlbums() {
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


// ALBUMSQUARE THAT DISPLAYS SEARCH VIEW
struct SearchAlbumSquare: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    let album: Album

    var body: some View {
        
        AsyncImage(url: URL(string: album.image.first(where: { $0.size == "large" })?.text ?? "")) { image in
            image
                .resizable()
                .onTapGesture {
                    vm.addAlbumToGrid(album: album, at: vm.selectedGridID ?? 0)
                    vm.hideSearchSheet()
                }
        } placeholder: {
            ProgressView()
        }
    }
}


struct AlbumSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumSearchView()
            .environmentObject(FortyScrollGridViewModel())
    }
}
