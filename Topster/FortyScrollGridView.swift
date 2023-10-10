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
        VStack {
            
            Text(vm.selectedGridID?.description ?? "")
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid1(showSearchSheet: $vm.showSearchSheet)
                }
            }
                   
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid2(showSearchSheet: $vm.showSearchSheet)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGrid3(showSearchSheet: $vm.showSearchSheet)
                }
            }
            
//            ScrollView(.horizontal) {
//                HStack {
//                    FortyScrollGrid4(showSearchSheet: $vm.showSearchSheet)
//                }
//            }
        }
        .scrollIndicators(.hidden)
        .padding()
        
        .sheet(isPresented: $vm.showSearchSheet) {
            AlbumSearchView()
        }
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

struct FortyScrollGrid1: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @Binding var showSearchSheet: Bool
    
    var body: some View {
        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5), id: \.key) { key, album in
            if album != nil {
                AlbumSquare(album: album!)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
            } else {
                Rectangle()
                    .foregroundColor(.blue)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
            }
        }
        .frame(width: 144, height: 144)
    }
}


struct FortyScrollGrid2: View {

    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @Binding var showSearchSheet: Bool

    // 6 -17
    var body: some View {
        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(5), id: \.key) { key, album in
            if album != nil {
                AlbumSquare(album: album!)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
            } else {
                Rectangle()
                    .foregroundColor(.blue)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
            }
        }
        .frame(width: 120, height: 120)
    }
}

struct FortyScrollGrid3: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @Binding var showSearchSheet: Bool

    var body: some View {
        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(18), id: \.key) { key, album in
            if album != nil {
                AlbumSquare(album: album!)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
            } else {
                Rectangle()
                    .foregroundColor(.blue)
                    .onTapGesture {
                        vm.selectedGridID = key
                        vm.toggleSheet()
                    }
            }
        }
        .frame(width: 96, height: 96)
    }
}

//struct FortyScrollGrid4: View {
//
//    @Binding var showSearchSheet: Bool
//
//    var body: some View {
//        ForEach(32...40, id: \.self) { index in
//            Rectangle()
//                .frame(width: 72, height: 72)
//                .opacity(0.3)
//        }
//        .onTapGesture {
//            showSearchSheet.toggle()
//        }
//    }
//}


struct FortyScrollGridView_Previews: PreviewProvider {
    static var previews: some View {
        FortyScrollGridView()
            .environmentObject(FortyScrollGridViewModel())
    }
}

