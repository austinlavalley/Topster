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
                //            Button("print album") {
                //                print(
                //                    vm.savedGrids.description
                //                )
                //            }
                
//                ForEach(Array(vm.savedGrids.enumerated()), id: \.offset) { index, grid in
//                    Text(grid.values.first?.map({ album in
//                        album.name
//                    }) ?? "no album name?")
//                }
                
                ForEach(Array(vm.savedGrids.enumerated()), id: \.offset) { index, grid in
                    
                    
                    HStack {
                        ForEach(grid.sorted(by: { $0.key < $1.key }), id: \.key) { key, album in
                            if album != nil {
//                                Text(album?.name ?? "")
                                AlbumSquare(album: album!)
                            } 
                        }
                    }
                    
                    
                }
            }
        }
    }
}
