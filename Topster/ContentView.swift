//
//  ContentView.swift
//  Topster
//
//  Created by Austin Lavalley on 8/27/23.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        TabView {

            FortyScrollGridView()
//            DraggableGridSetup()
                .tabItem {
                    Text("Current grid")
                }
            
            SavedGridsListView()
                .tabItem {
                    Text("Saved grids")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FortyScrollGridViewModel())
    }
}


struct SavedGridsListView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                
                // for each GRID in the array of saved grids
                ForEach(Array(vm.savedGrids.enumerated()), id: \.offset) { index, grid in
                    
                    ScrollView(.horizontal) {
                        HStack {
                            // for each [key: album] pair in each individual grid (i.e, "Fav rock albums", "fav 70s", etc)
                            ForEach(grid.sorted(by: { $0.key < $1.key }), id: \.key) { key, album in
                                if album != nil {
                                    //                                Text(album?.name ?? "")
                                    AlbumSquare(album: album!)
                                } else {
                                    //                                Rectangle().foregroundColor(.gray)
                                }
                            }
                            .frame(width: 96, height: 96)
                        }
//                        .padding(.horizontal)
                        
                        
                    }
                    .padding()
                    .background(.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
    }
}
