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

            FortyGridView()
                .tabItem {
                    Label("Grid", systemImage: "square.grid.3x3")
                }
            
            SavedGridsListView()
                .tabItem {
                    Label("Saved", systemImage: "book.pages")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "lines.measurement.vertical")
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



