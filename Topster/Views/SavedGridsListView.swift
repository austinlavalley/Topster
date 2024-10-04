//
//  SavedGridsListView.swift
//  Topster
//
//  Created by Austin Lavalley on 11/3/23.
//

import SwiftUI

struct SavedGridsListView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @State private var showDeleteConfirm = false
        
    var body: some View {
        NavigationStack {
            if /*!vm.savedGrids.isEmpty*/ false {
                    VStack {
                        ScrollView {

                        // for each GRID in the array of saved grids
                        ForEach(Array(vm.savedGrids.enumerated()), id: \.offset) { index, grid in
                            
                            if grid.grid.values.contains(where: { $0 != nil }) {
                                SavedGridCardPreviewView(grid: grid, currentIndex: index)
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                        
                }
                    .toolbar {
                        ToolbarItem {
                            Button {
                                showDeleteConfirm.toggle()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(vm.currentActiveGrid == nil)
                        }
                    }
                
                .navigationTitle("Saved grids")
                
                
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image("player")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 48)
                    
                    VStack(spacing: 4) {
                        Text("No grids saved yet").font(.title2).bold()
                        Text("All of your saved grids will show up here").font(.subheadline).foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .confirmationDialog("Delete this grid?", isPresented: $showDeleteConfirm) {
            Button("Delete grid", role: .destructive) {
                withAnimation {
                    vm.removeFromSavedGrids(at: vm.currentActiveGrid!)
                    vm.currentActiveGrid = nil
                    vm.clearGrid()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be ctrl + z'd")
        }
        
    }
}

struct SavedGridsListView_Previews: PreviewProvider {
    static var previews: some View {
        SavedGridsListView()
            .environmentObject(FortyScrollGridViewModel())
    }
}
