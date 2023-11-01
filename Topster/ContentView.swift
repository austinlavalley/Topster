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
                    
                    SavedGridCardPreviewView(grid: grid, currentIndex: index)
                    
                    
                }
                .padding(.horizontal)
            }
        }
    }
}
