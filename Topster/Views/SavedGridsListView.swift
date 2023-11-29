//
//  SavedGridsListView.swift
//  Topster
//
//  Created by Austin Lavalley on 11/3/23.
//

import SwiftUI

struct SavedGridsListView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
            
                    // for each GRID in the array of saved grids
                    ForEach(Array(vm.savedGrids.enumerated()), id: \.offset) { index, grid in
                        
                        SavedGridCardPreviewView(grid: grid, currentIndex: index)
                        
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Saved grids")
        }
    }
}

struct SavedGridsListView_Previews: PreviewProvider {
    static var previews: some View {
        SavedGridsListView()
            .environmentObject(FortyScrollGridViewModel())
    }
}
