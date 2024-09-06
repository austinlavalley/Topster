//
//  FortyScrollGridView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/2/23.
//

import SwiftUI


struct FortyGridView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @State private var saveButtonText = "Save grid"
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
//                Text(vm.currentActiveGrid?.description ?? "NONE")
                
                ScrollView {
                    GridContent()
                        .frame(maxHeight: .infinity)
                        .scrollIndicators(.hidden)
                        .padding()
                        .navigationBarTitleDisplayMode(.inline)
//                        .navigationTitle("Top 40 Chart")
                        .navigationTitle((vm.currentActiveGrid != nil) ? "Grid #\(vm.currentActiveGrid ?? 0)" : "Unsaved Grid")
                }
                
                HStack {
                    Button("Export") {
                        vm.showExportSheet.toggle()
                    }
                    .buttonStyle(DefaultSecondary())
                    .disabled(vm.FortyGridDict.allSatisfy({ $0.value == nil }))
                    
                    AnimatedSaveButtonView(buttonText: "Save grid", buttonActionText: "Saved", noAlbums: vm.FortyGridDict.allSatisfy({ $0.value == nil }), isSecondaryStyle: false)
                        .disabled(vm.FortyGridDict.allSatisfy({ $0.value == nil })) // disables save button if the grid is empty, can't do it inside buttonstyle
                    
                }
                .frame(maxWidth: .infinity)
                .padding()
                
            }
            
            
            .sheet(isPresented: $vm.showSearchSheet) {
                AlbumSearchView()
                    .presentationDetents([.fraction(0.85)])
            }
            
            
            
            .confirmationDialog("Remove album", isPresented: $vm.pressShowRemove, actions: {
                Button("yes", role: .destructive) {
                    vm.removeAlbumFromGrid(at: vm.selectedGridID ?? 0)
                }
            })
            
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("New grid") {
                            vm.clearGrid()
                            vm.currentActiveGrid = nil
                        }
                        
                        Button("Delete grid from saved") {
                            withAnimation(.bouncy) {
                                vm.removeFromSavedGrids(at: vm.currentActiveGrid!)
                                vm.currentActiveGrid = nil
                                vm.clearGrid()
                            }
                        }
                    } label: {
                        Label("", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showExportSheet) {
            RenderView()
        }
        
        .onAppear {
            if vm.currentActiveGrid != nil {
                vm.FortyGridDict = vm.savedGrids[vm.currentActiveGrid!]
            }
        }
    }
}



// ALBUMSQAURE FOR MAIN GRID VIEW THAT REFRESHES VIEW
struct AsyncAlbumSquare: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    let album: Album
    
    var body: some View {
        AsyncImage(url: URL(string: album.image.first(where: { $0.size == "large"})?.text ?? "")) { image in
            image
                .resizable()
        } placeholder: {
            ProgressView()
        }
    }
}

// ALBUMSQUARE FOR ELSEWHERE IN APP
struct AlbumSquare: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    let album: Album
    
    var body: some View {
        VStack {
            InternetImage(url: album.image.first(where: { $0.size == "large"})?.text ?? "") { image in
                image
                    .resizable()
            }
        }
    }
}






struct FortyGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyGridView()
            .environmentObject(FortyScrollGridViewModel())
    }
}

