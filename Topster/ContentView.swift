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
//            FortyTwoGridView()
//                .tabItem {
//                    Text("42 grid")
//                }
//
//            FortyGridView()
//                .tabItem {
//                    Text("40 grid")
//                }
//
//            CollageView()
//                .tabItem {
//                    Text("Collage")
//                }

            FortyScrollGridView()
                .tabItem {
                    Text("Current grid")
                }
            
            Text("y0")
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
