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
//                    Text("Current grid")
                    Label("Current grid", systemImage: "house")
                }
            
            SavedGridsListView()
                .tabItem {
                    Label("Saved grids", systemImage: "book.closed")
                }
            
            Text("settings, y0")
                .tabItem {
                    Label("Settings?", systemImage: "person.crop.circle")
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



