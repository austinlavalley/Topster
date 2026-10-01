//
//  GridContent.swift
//  Topster
//
//  Created by Austin Lavalley on 11/22/23.
//

import SwiftUI

struct GridContent: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    /// Drag-to-swap, shared with every cell. The held cover is drawn in this
    /// view's overlay rather than inside a row, because each row is its own
    /// horizontal scroll view and would clip it.
    @State private var drag = SlotDrag()

    var body: some View {
        layout
            .coordinateSpace(.named(GridSpace.name))
            .onPreferenceChange(SlotFramesKey.self) { frames in
                drag.frames = frames
            }
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            drag.bounds = CGRect(origin: .zero, size: geometry.size)
                            drag.windowOrigin = geometry.frame(in: .global).origin
                        }
                        .onChange(of: geometry.size) { _, size in
                            drag.bounds = CGRect(origin: .zero, size: size)
                        }
                        // Moves when the page scrolls; still while a cover is
                        // held, since the page cannot scroll then.
                        .onChange(of: geometry.frame(in: .global).origin) { _, origin in
                            drag.windowOrigin = origin
                        }
                }
            }
            .overlay { FloatingCover(drag: drag) }
            // The long press already stops the scroll view under the finger;
            // this also stops a second finger scrolling a row. Edge scrolling
            // sets the row's offset directly and still runs.
            .scrollDisabled(drag.isHeld)
            .preference(key: SlotHeldKey.self, value: drag.isHeld)
            .sensoryFeedback(.impact(weight: .light), trigger: drag.isHeld) { wasHeld, isHeld in
                !wasHeld && isHeld
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: drag.landings)
            .environment(drag)
    }

    @ViewBuilder private var layout: some View {
        switch vm.activeGridType {
        case .fortyTwo:
            FortyTwoGridMaster()
        case .twenty:
            TwentyGridMaster()
        case .twentyWide:
            TwentyGridMasterWide()
        case .twentyFive:
            TwentyFiveGridMaster()
        }
    }
}









struct TwentyGridMasterWide: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(15).dropFirst(10), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(15), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
        }
        
    }
}


struct TwentyGridMaster: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(4).dropFirst(0), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(8).dropFirst(4), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(12).dropFirst(8), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(16).dropFirst(12), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(16), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
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
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(15).dropFirst(10), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(15), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(25).dropFirst(20), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
        }
        
    }
}




struct FortyTwoGridMaster: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 120, height: 120)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 120, height: 120)
                }
            }
            
            
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(16).dropFirst(10), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(22).dropFirst(16), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 96, height: 96)
                }
            }
            
            
            
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(32).dropFirst(22), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 64, height: 64)
                }
            }
            
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(42).dropFirst(32), id: \.key) { key, album in
                        GridSlotCell(key: key, album: album)
                    }
                    .frame(width: 64, height: 64)
                }
            }
            
        }
    }
}




struct GridContent_Previews: PreviewProvider {
    static var previews: some View {
        GridContent()
            .environmentObject(FortyScrollGridViewModel())
    }
}
