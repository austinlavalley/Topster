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
        switch vm.activeGridType {
        case .forty:
            FortyGridMaster()
        case .twenty:
            TwentyGridMaster()
        case .twentyWide:
            TwentyGridMasterWide()
        case .twentyFive:
            TwentyFiveGridMaster()
        }
    }
}









struct TwentyGridMaster: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(15).dropFirst(10), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(15), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
        }
        
    }
}


struct TwentyGridMasterWide: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(4).dropFirst(0), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(8).dropFirst(4), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(12).dropFirst(8), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(16).dropFirst(12), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(16), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
        }
        
    }
}




struct TwentyFiveGridMaster: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(15).dropFirst(10), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(15), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(25).dropFirst(20), id: \.key) { key, album in
                        if album != nil {
                            AsyncAlbumSquare(album: album!)
                                .onTapGesture {
                                    vm.selectedGridID = key
                                    vm.toggleSheet()
                                }
                        } else {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        vm.selectedGridID = key
                                        vm.toggleSheet()
                                    }
                                
                                Image(systemName: "plus").bold().foregroundColor(.secondary)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
        }
        
    }
}






struct FortyGridMaster: View {
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridRows(start: 0, end: 5, size: 144, squareColor: .secondary)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridRows(start: 5, end: 17, size: 120, squareColor: .secondary.opacity(0.8))
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridRows(start: 17, end: 31, size: 96, squareColor: .secondary.opacity(0.6))
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    FortyScrollGridRows(start: 31, end: 40, size: 72, squareColor: .secondary.opacity(0.4))
                    
                }
            }
        }
    }
    
    
    struct FortyScrollGridRows: View {
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
}





struct GridContent_Previews: PreviewProvider {
    static var previews: some View {
        GridContent()
            .environmentObject(FortyScrollGridViewModel())
    }
}
