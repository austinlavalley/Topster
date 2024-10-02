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
    @State private var showNewSheet = false
    
    @State private var showingPopover = false
    @State private var customGridName = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                
//                Text(vm.currentActiveGrid?.description ?? "NIL")
//                Text(vm.currentActiveGrid != nil ? (vm.savedGrids[vm.currentActiveGrid!].grid == vm.FortyGridDict ? "EQUAL" : "NOT EQUAL") : "currentActiveGrid = NIL")
                
                ScrollView {
                    GridContent()
                        .frame(maxHeight: .infinity)
                        .scrollIndicators(.hidden)
                        .padding()
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle((vm.currentActiveGrid != nil) ? vm.savedGrids[vm.currentActiveGrid!].name != nil ? "\(vm.savedGrids[vm.currentActiveGrid!].name ?? "BROKEN OPTIONAL")" : "Unnamed Grid \(vm.currentActiveGrid ?? 0)" : "Unsaved Grid" )
                }
                
                HStack {
                    Button("Export") {
                        vm.showExportSheet.toggle()
                    }
                    .buttonStyle(DefaultSecondary())
                    .disabled(vm.FortyGridDict.allSatisfy({ $0.value == nil }))
                    
                    AnimatedSaveButtonView(buttonText: "Save grid", buttonActionText: "Saved", isSecondaryStyle: false)
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
                            showingPopover.toggle()
                        } label: {
                            Label("Name grid", systemImage: "pencil")
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
                
                Text("Choose grid layout").font(.title2).bold()
                
                VStack {
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .fortyTwo
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "42 Albums", subtitle: "Multi-sized rows", isSelected: vm.activeGridType == .fortyTwo)
                    }.tint(.primary)
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .twentyFive
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "25 Albums", subtitle: "5x5 Grid", isSelected: vm.activeGridType == .twentyFive)
                    }.tint(.primary)
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .twenty
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "20 Albums", subtitle: "5x4 Grid", isSelected: vm.activeGridType == .twenty)
                    }.tint(.primary)
                    
                    Button {
                        withAnimation(.spring) {
                            vm.activeGridType = .twentyWide
                            showNewSheet = false
                        }
                    } label: {
                        GridLayoutSelectOption(title: "20 Albums (Wide)", subtitle: "4x5 Grid", isSelected: vm.activeGridType == .twentyWide)
                    }.tint(.primary)
                }.padding()
            }
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
        }
        
        .popover(isPresented: $showingPopover) {
            VStack(spacing: 24) {
//                Spacer()
                
                VStack(spacing: 8) {
                    Text("Name this grid")
                        .font(.title3).bold()
                    Text("This is the name that will show in your saved list, and can be changed at any time.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }.padding(12)
                
                TextField("Grid Name", text: $customGridName)
                    .padding()
                    .background(.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
//                Spacer()
                
                Button("Save") {
                    vm.updateName(name: customGridName)
                    showingPopover = false
                    customGridName = ""
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(customGridName.isEmpty ? Color.secondary : .blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .bold()
                .disabled(customGridName.isEmpty)
            }
            .padding()
//            .frame(width: 300, height: 200)
            .presentationDetents([.fraction(0.4)])
        }
        
        .onAppear {
            if vm.currentActiveGrid != nil {
                vm.FortyGridDict = vm.savedGrids[vm.currentActiveGrid!].grid
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

