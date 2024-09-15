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
            if !vm.savedGrids.isEmpty {
                ScrollView {
                    VStack {
                        
                        // for each GRID in the array of saved grids
                        ForEach(Array(vm.savedGrids.enumerated()), id: \.offset) { index, grid in
                            
                            if grid.grid.values.contains(where: { $0 != nil }) {
                                SavedGridCardPreviewView(grid: grid, currentIndex: index)
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationTitle("Saved grids")
            } else {
                VStack {
                    Spacer()
                    
                    Text("no saved grids")
                    
                    Spacer()
                }
            }
        }
    }
}

struct SavedGridsListView_Previews: PreviewProvider {
    static var previews: some View {
        SavedGridsListView()
            .environmentObject(FortyScrollGridViewModel())
    }
}
