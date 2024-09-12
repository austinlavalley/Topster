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
    @State private var showNewSheet = true
    
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
                // Using a label instead of a button to incorporate hierarchical icons
                    Label("", systemImage: "crop.rotate")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                        .onTapGesture {
                            showNewSheet.toggle()
                        }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button() {
                            vm.clearGrid()
                            vm.currentActiveGrid = nil
                        } label: {
                            Label("New grid", systemImage: "plus")
                        }
                        
                        Button() {
                            showNewSheet.toggle()
                        } label: {
                            Label("Change grid layout", systemImage: "crop.rotate")
                        }
                        
                        Button() {
                            withAnimation(.bouncy) {
                                vm.removeFromSavedGrids(at: vm.currentActiveGrid!)
                                vm.currentActiveGrid = nil
                                vm.clearGrid()
                            }
                        } label: {
                            Label("Remove grid from saved", systemImage: "trash")
                        }
                        .disabled(vm.currentActiveGrid == nil)
                    } label: {
                        Label("", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showExportSheet) {
            RenderView()
        }
        
        .sheet(isPresented: $showNewSheet) {
            VStack(spacing: 0) {
            //            VStack {
            //                Button("forty sheet") {
            //                    withAnimation(.spring) {
            //                        vm.activeGridType = .forty
            //                        showNewSheet = false
            //                    }
            //                }
            //                Button("twenty sheet") {
            //                    withAnimation(.spring) {
            //                        vm.activeGridType = .twenty
            //                        showNewSheet = false
            //                    }
            //                }
            //                Button("twentyWide sheet") {
            //                    withAnimation(.spring) {
            //                        vm.activeGridType = .twentyWide
            //                        showNewSheet = false
            //                    }
            //                }
            //                Button("twentyfive sheet") {
            //                    withAnimation(.spring) {
            //                        vm.activeGridType = .twentyFive
            //                        showNewSheet = false
            //                    }
            //                }
            //
            //            }
                
                Text("Choose layout").font(.title).bold()
                
//            GridLayoutSheet().padding()
                
                VStack {
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .forty
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "Forty", subtitle: "Forty grid", isSelected: vm.activeGridType == .forty)
                    }.tint(.primary)
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .twentyFive
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "Twenty-five", subtitle: "Forty grid", isSelected: vm.activeGridType == .twentyFive)
                    }.tint(.primary)
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .twenty
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "Twenty", subtitle: "Forty grid", isSelected: vm.activeGridType == .twenty)
                    }.tint(.primary)
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .twentyWide
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "Twenty", subtitle: "Forty grid", isSelected: vm.activeGridType == .twentyWide)
                    }.tint(.primary)
                }
        }
            .padding(.top, 24)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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

