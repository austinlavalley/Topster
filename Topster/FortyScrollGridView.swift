//
//  FortyScrollGridView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/2/23.
//

import SwiftUI

struct FortyScrollGridView: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
            
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
//                Text(vm.pressShowRemove.description)
                
                ScrollView(.horizontal) {
                    HStack {
                        FortyScrollGridMaster(start: 0, end: 5, size: 144, squareColor: .secondary)
                    }
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        FortyScrollGridMaster(start: 5, end: 18, size: 120, squareColor: .secondary.opacity(0.8))
                    }
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        FortyScrollGridMaster(start: 18, end: 31, size: 96, squareColor: .secondary.opacity(0.6))
                    }
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        FortyScrollGridMaster(start: 31, end: 40, size: 72, squareColor: .secondary.opacity(0.4))

                    }
                }
                
                Spacer()
                
                HStack {
                    Button("Export grid") {}
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                        .background(.red)
                        .disabled(true)
                    
                    Button("Add to saved grids") {
                        vm.addToSavedGrids(grid: vm.FortyGridDict)
                    }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)

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
    }
}



// ALBUMSQAURE FOR MAIN GRID VIEW
struct AlbumSquare: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    let album: Album

    var body: some View {
        AsyncImage(url: URL(string: album.image.first(where: { $0.size == "large" })?.text ?? "")) { image in
            image
                .resizable()
        } placeholder: {
            ProgressView()
        }
    }
}






struct FortyScrollGridMaster: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    let start: Int
    let end: Int
    let size: CGFloat
    let squareColor: Color
    
    var body: some View {
        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(end).dropFirst(start), id: \.key) { key, album in
            if album != nil {
                AlbumSquare(album: album!)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
//                    .onLongPressGesture {
//                        if ((vm.FortyGridDict[vm.selectedGridID ?? 0]?.flatMap({ _ in })) != nil) {
//                            vm.pressShowRemove.toggle()
//                        }
//                    }
            } else {
                ZStack {
                    Rectangle()
                        .foregroundColor(squareColor)
                        .onTapGesture {
                            vm.selectedGridID = key
                            vm.toggleSheet()
                        }
                    
                    Image(systemName: "plus").bold().foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}


struct FortyScrollGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyScrollGridView()
            .environmentObject(FortyScrollGridViewModel())
    }
}

