//
//  FortyScrollGridView.swift
//  Topster
//
//  Created by Austin Lavalley on 9/2/23.
//

import SwiftUI

struct FortyGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false

    var body: some View {
        VStack(alignment: .center) {
            // topster row sizing: 150 125 125 100 100 75
            
            // 5x1 row
            HStack(spacing: 10) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 300, height: 300)
            } .frame(width: 1600)
            
            // 6x2 rows
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(11).dropFirst(5), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 250, height: 250)
            }.frame(width: 1600)
            
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(11), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 250, height: 250)
            }.frame(width: 1600)
            
            
            // 7x2 rows
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(24).dropFirst(17), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 200, height: 200)
            }
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(24), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                            .onTapGesture {
                                vm.selectedGridID = key
                                vm.toggleSheet()
                            }
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 200, height: 200)
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
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 150, height: 150)
            }
        }
        .frame(width: 1668, height: 1518)
        .background(darkModeEnabled ? Color.black : Color.white)
    }
}




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
                RenderView()
            }
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






struct FortyScrollGridMaster: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    let start: Int
    let end: Int
    let size: CGFloat
    let squareColor: Color
    
    var body: some View {
        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(end).dropFirst(start), id: \.key) { key, album in
            if album != nil {
                AsyncAlbumSquare(album: album!)
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


struct FortyGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyGridView()
            .environmentObject(FortyScrollGridViewModel())
    }
}

