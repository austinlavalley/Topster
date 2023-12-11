//
//  GridContent.swift
//  Topster
//
//  Created by Austin Lavalley on 11/22/23.
//

import SwiftUI

struct GridContent: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridMaster(start: 0, end: 5, size: 144, squareColor: .secondary)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridMaster(start: 5, end: 17, size: 120, squareColor: .secondary.opacity(0.8))
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridMaster(start: 17, end: 31, size: 96, squareColor: .secondary.opacity(0.6))
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridMaster(start: 31, end: 40, size: 72, squareColor: .secondary.opacity(0.4))
                    
                }
            }
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
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(width: size, height: size)
    }
}

struct GridContent_Previews: PreviewProvider {
    static var previews: some View {
        GridContent()
    }
}
