//
//  FortyScrollGridView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/2/23.
//

import SwiftUI

struct TestViewForSnapshot: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle()
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                        }
                    }
                } .frame(width: 288, height: 288)
            }
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(18).dropFirst(5), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle()
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                        }
                    }
                } .frame(width: 240, height: 240)
            }
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(18), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle()
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                        }
                    }
                } .frame(width: 192, height: 192)
            }
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(40).dropFirst(31), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle()
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                        }
                    }
                } .frame(width: 144, height: 144)
            }
        }
//        .frame(width: 1280, height: 720)
    }
}


struct GridContent: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        Spacer()
        
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
    }
}

struct FortyScrollGridView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @State private var saveButtonText = "Save grid"
    @State private var showExportSheet = false
            
    var body: some View {
        NavigationStack {
            VStack {
                GridContent()
                    .background(Color.red)
                
                Spacer()
                
                HStack {
                    Button("Export something") {
                        vm.showExportSheet.toggle()
                    }
                    
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
            RenderView(album: (vm.FortyGridDict[1]!!))
        }
    }
}


struct SaveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? .red : .blue)
            .bold()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.white)
    }
}


struct AnimatedSaveButtonView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    @State private var isAnimating = false
    @State private var isSuccess = false
    
    @State var buttonText: String
    @State var buttonActionText: String
    
    let isSecondaryStyle: Bool

    var body: some View {
        Button(action: {
            self.isAnimating = true
            self.isSuccess = true
            
            vm.addToSavedGrids(grid: vm.FortyGridDict)

            // After a delay, reset the animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring()) {
                    self.isAnimating = false
                }
            }
        }) {
            Label(isAnimating ? buttonActionText : buttonText, systemImage: isAnimating ? "checkmark" : "")
                .frame(maxWidth: .infinity)
                .foregroundColor(isSecondaryStyle ? Color.blue : Color.white)
                .bold()
                .padding()
                .background(isAnimating ? (isSecondaryStyle ? Color.gray.opacity(0.25) : Color.green) : (isSecondaryStyle ? Color.gray.opacity(0.25) : Color.blue))
                .cornerRadius(12)
        }
        .disabled(isAnimating) // Disable the button while animating
    }
}






// ALBUMSQAURE FOR MAIN GRID VIEW
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

