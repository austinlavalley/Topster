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
                   
//            ScrollView(.horizontal) {
//                HStack {
//                    FortyScrollGrid2(showSearchSheet: $vm.showSearchSheet)
//                }
//            }
//            ScrollView(.horizontal) {
//                HStack {
//                    FortyScrollGrid3(showSearchSheet: $vm.showSearchSheet)
//                }
//            }
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


struct FortyScrollGrid1: View {
    
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @Binding var showSearchSheet: Bool
    
    var body: some View {
        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }), id: \.key) { key, album in
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
//        .onTapGesture {
//            vm.toggleSheet()
//        }
    }
}


// ALBUMSQAURE FOR MAIN GRID VIEW
struct AlbumSquare: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    let album: Album
    
    // here is where need to send to vm WHICH square we are tapping on/initiating

    var body: some View {

        AsyncImage(url: URL(string: album.image.first(where: { $0.size == "large" })?.text ?? "")) { image in
            image
                .resizable()
        } placeholder: {
            ProgressView()
        }
    }
}

//struct FortyScrollGrid2: View {
//
//    @Binding var showSearchSheet: Bool
//
//    var body: some View {
//        ForEach(6...17, id: \.self) { index in
//            Rectangle()
//                .frame(width: 120, height: 120)
//                .opacity(0.8)
//        }
//        .onTapGesture {
//            showSearchSheet.toggle()
//        }
//    }
//}
//
//struct FortyScrollGrid3: View {
//
//    @Binding var showSearchSheet: Bool
//
//    var body: some View {
//        ForEach(18...31, id: \.self) { index in
//            Rectangle()
//                .frame(width: 96, height: 96)
//                .opacity(0.5)
//        }
//        .onTapGesture {
//            showSearchSheet.toggle()
//        }
//    }
//}
//
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

