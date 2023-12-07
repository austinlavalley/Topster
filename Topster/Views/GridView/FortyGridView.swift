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
                ScrollView {
                    GridContent()
                        .frame(maxHeight: .infinity)
                        .scrollIndicators(.hidden)
                        .padding()
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Top 40 Chart")
//                        .background(Color.red.opacity(0.25))
                    
                }
                
                HStack {
                    Button("Export") {
                        vm.showExportSheet.toggle()
                    }
                    .buttonStyle(DefaultSecondary())
                    
                    AnimatedSaveButtonView(buttonText: "Save grid", buttonActionText: "Grid saved", isSecondaryStyle: false)
                    
                }
                .frame(maxWidth: .infinity)
                .padding()
//                .background(Color.red.opacity(0.25))
                
                
            }
//                .background(Color.red.opacity(0.25))
//            }

            
            
            .sheet(isPresented: $vm.showSearchSheet) {
                AlbumSearchView()
                    .presentationDetents([.fraction(0.65), .large])
            }
            

            
            .confirmationDialog("Remove album", isPresented: $vm.pressShowRemove, actions: {
                Button("yes", role: .destructive) {
                    vm.removeAlbumFromGrid(at: vm.selectedGridID ?? 0)
                }
            })
            
            .toolbar {
                ToolbarItem {
                    Menu {
                        Text("yo")
                        Button("Reset grid") {
                            vm.clearGrid()
                            vm.currentActiveGrid = nil
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
            Rectangle().fill(.purple)
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

