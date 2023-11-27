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
            ScrollView {
                VStack {
//                    ForEach(vm.FortyGridDict.sorted(by: {$0.key < $1.key}), id: \.key) { key, album in
//                        if album != nil {
//                            Text(album!.name)
//                        }
//                    }
                    
                    GridContent()
                    
                    Spacer()
                    
                    HStack {
                        Button("Export") {
                            vm.showExportSheet.toggle()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.accentColor)
                        .bold()
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(12)
                        
                        AnimatedSaveButtonView(buttonText: "Save grid", buttonActionText: "Grid saved", isSecondaryStyle: false)
                        
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                .scrollIndicators(.hidden)
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Top 40 Chart")
                
                .toolbar {
                    ToolbarItem {
                        Menu {
                            Text("yo")
                            Button("Reset grid") { vm.clearGrid() }
                        } label: {
                            Label("", systemImage: "ellipsis.circle")
                        }
                    }
                }
                
                
                .sheet(isPresented: $vm.showSearchSheet) {
                    AlbumSearchView()
                        .presentationDetents([.fraction(0.65), .large])
                }
            }
            .confirmationDialog("Remove album", isPresented: $vm.pressShowRemove, actions: {
                Button("yes", role: .destructive) {
                    vm.removeAlbumFromGrid(at: vm.selectedGridID ?? 0)
                }
            })
            .sheet(isPresented: $vm.showExportSheet) {
                RenderView()
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
        InternetImage(url: album.image.first(where: { $0.size == "large"})?.text ?? "") { image in
            image
                .resizable()
        }
    }
}


struct FortyGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyGridView()
            .environmentObject(FortyScrollGridViewModel())
    }
}

