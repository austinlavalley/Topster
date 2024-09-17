//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import SwiftUI


struct RenderView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @Environment(\.presentationMode) var presentationMode

    
    @State private var snapshot: UIImage?
    
    
    @State var showLoading = true
    @State private var showingSavedToPhotosSuccess = false
    
    @State private var showEdits = false
    
    
    var body: some View {
        
        VStack {
            ZStack {
                VStack(spacing: 24) {
                    
                    VStack {
                        HStack {
                            Button {
                                showEdits.toggle()
                            } label: {
                                Label(
                                    title: { Text("") },
                                    icon: { Image(systemName: "slider.horizontal.3").font(.title2).bold() })
                            }
                            .foregroundStyle(.secondary)

                            Spacer()
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Label(
                                    title: { Text("") },
                                    icon: { Image(systemName: "xmark").font(.title2) })
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                    }.padding(.top, 24)


                    
                    // snapshot of grid to export
                    if let image = snapshot {
                        Spacer()
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                        
                        
                        Spacer()
                        // export buttons
                        VStack {
                            ShareLink(
                                item: Image(uiImage: snapshot!),
                                preview: SharePreview((vm.currentActiveGrid != nil) ? "Grid #\(vm.currentActiveGrid ?? 0)" : "Unsaved Grid", image: Image(uiImage: snapshot!), icon: sharePreview)
                            )
                            .buttonStyle(DefaultSecondary())
                            
                            if let snapshot = snapshot {
                                Button("Save to Photos") {
                                    UIImageWriteToSavedPhotosAlbum(snapshot, nil, nil, nil)
                                    
                                    withAnimation {
                                        showingSavedToPhotosSuccess = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation {
                                            showingSavedToPhotosSuccess = false
                                        }
                                    }
                                    
                                    //                                presentationMode.wrappedValue.dismiss()
                                    
                                }
                                .buttonStyle(DefaultPrimary())
                            }
                        }.padding()
                    }
                }
                
                
                if showingSavedToPhotosSuccess {
                    VStack {
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.65))
                                .frame(width: 240, height: 64)
                                .padding()
                            
                            Text("Grid saved to camera roll").foregroundColor(.white).bold()
                        }
                        Spacer()
                    }
                }
                
                if showLoading {
                    LoadingView()
                    //                    .transition(.opacity)
                        .zIndex(1)
                }
            }
            
            
            .onAppear {
                generateSnapshot()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    generateSnapshot()
                    
                    withAnimation {
                        showLoading = false
                    }
                }
            }
            
        // when we change the type of the current grid, ensure we're regenerating the export view (MAYBE DELETE IF NOT MAKING CHANGES TO GRID TYPE ON THIS PAGE?)
            .onChange(of: vm.activeGridType, { _, _ in
                generateSnapshot()
            })
            
            
            .confirmationDialog("", isPresented: $showEdits) {
                Button(vm.tempExportDarkMode ? "Light background" : "Dark background") {
                    vm.tempExportDarkMode.toggle()
                    generateSnapshot()
                }
            }
            
        }

    }
    
    var sharePreview: some Transferable {
        Image(systemName: "text.book.closed.fill")
    }
}





extension RenderView {
    func generateSnapshot() {
        Task {
            let renderer = ImageRenderer(content:
                                         
                ExportView().environmentObject(vm)
                                         
            )
            
            if let image = renderer.uiImage {
                self.snapshot = image
            }
        }
    }
}
    
struct ExportView: View {
    @EnvironmentObject var vm: FortyScrollGridViewModel

    var body: some View {
        Group {
            switch vm.activeGridType {
            case .forty:
                TwentyFiveGridExportView()
            case .twenty:
                TwentyGridExportView()
            case .twentyWide:
                TwentyGridExportViewWide()
            case .twentyFive:
                TwentyFiveGridExportView()
            }
        }
    }
}





struct RenderView_Previews: PreviewProvider {
    static var previews: some View {
        RenderView()
            .environmentObject(FortyScrollGridViewModel())
    }
}












// ACTUAL VIEW THAT IS BEING EXPORTED

struct FortyGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false
    
    @State private var vacant5x17 = false
    @State private var vacant17x31 = false


    var body: some View {
        
        VStack(alignment: .center) {
            // topster row sizing: 150 125 125 100 100 75
            
            
            // 5x1 row
            HStack(spacing: 10) {
                // local var to determine if the values of individual row are all NIL
                let allAlbumsNil = vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0).allSatisfy { $0.value == nil }

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        if !allAlbumsNil {
                            Rectangle().fill(.secondary.opacity(0.5))
                        }
                    }
                } .frame(width: 300, height: 300)
            } .frame(width: 1600)


            
            
            
            
            // 6x2 rows
            VStack {
                
            // hides first 6x row if no albums chosen in that range
                if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(11).dropFirst(5).allSatisfy({ $0.value == nil }) {
                    HStack {
                        let allAlbumsNil = vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(11).dropFirst(5).allSatisfy { $0.value == nil }
                        
                        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(11).dropFirst(5), id: \.key) { key, album in
                            if album != nil {
                                AlbumSquare(album: album!)
                            } else {
                                if !allAlbumsNil {
                                    Rectangle().fill(.secondary.opacity(0.5))
                                }
                            }
                        }
                        .frame(width: 250, height: 250)
                    }.frame(width: 1600)
                }
                
                
            // hides second 6x row if no albums chosen in that range
                if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(11).allSatisfy({ $0.value == nil }) {
                    HStack {
                        let allAlbumsNil = vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(11).allSatisfy { $0.value == nil }
                        
                        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(11), id: \.key) { key, album in
                            if album != nil {
                                AlbumSquare(album: album!)
                            } else {
                                if !allAlbumsNil {
                                    Rectangle().fill(.secondary.opacity(0.5))
                                }
                            }
                        } .frame(width: 250, height: 250)
                    }.frame(width: 1600)
                }
                
            }
            
            
            
            
            // 7x2 rows
            VStack {
                
                if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(24).dropFirst(17).allSatisfy({ $0.value == nil }) {
                    HStack {
                        let allAlbumsNil = vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(17).allSatisfy { $0.value == nil }
                        
                        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(24).dropFirst(17), id: \.key) { key, album in
                            if album != nil {
                                AlbumSquare(album: album!)
                            } else {
                                if !allAlbumsNil {
                                    Rectangle().fill(.secondary.opacity(0.5))
                                }
                            }
                        } .frame(width: 200, height: 200)
                    }
                }
                
                
                if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(24).allSatisfy({ $0.value == nil }) {
                    HStack {
                        let allAlbumsNil = vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(17).allSatisfy { $0.value == nil }
                        
                        ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(24), id: \.key) { key, album in
                            if album != nil {
                                AlbumSquare(album: album!)
                            } else {
                                if !allAlbumsNil {
                                    Rectangle().fill(.secondary.opacity(0.5))
                                }
                            }
                        } .frame(width: 200, height: 200)
                    }
                }
            }
            .padding(.top, vacant5x17 ? (vacant17x31 ? 5 : 10) : 0)

            
            
            
            
            
            HStack {
                let allAlbumsNil = vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(40).dropFirst(31).allSatisfy { $0.value == nil }

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(40).dropFirst(31), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        if !allAlbumsNil {
                            Rectangle().fill(.secondary.opacity(0.5))
                        }
                    }
                } .frame(width: 150, height: 150)
            }
            .padding(.top, vacant17x31 ? (vacant5x17 ? 5 : 10) : 0)

            
            
        }
        .frame(width: 1668/*, height: 1518*/)
        .padding()
        .background(darkModeEnabled ? vm.tempExportDarkMode != darkModeEnabled ? Color.white : Color.black :
                        vm.tempExportDarkMode != darkModeEnabled ? Color.black : Color.white)
        
        
        
    // on load, determine if/which middle rows are empty to adjust padding between
        .onAppear() {
            if vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(5).allSatisfy({ $0.value == nil }) {
                vacant5x17 = true
            }
            
            if vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(17).allSatisfy({ $0.value == nil }) {
                vacant17x31 = true
            }
        }
    }
}


struct FortyTwoGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false


    var body: some View {
        
        VStack(spacing: vm.globalSpacing) {
            
            HStack(spacing: vm.globalSpacing) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            
            
            
            
            HStack(spacing: vm.globalSpacing) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(16).dropFirst(10), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(22).dropFirst(16), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            
            
            
            
            HStack(spacing: vm.globalSpacing) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(32).dropFirst(22), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(42).dropFirst(32), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            
            
        }
        .frame(width: 3366/*, minHeight: 3366*/)
        .padding(72)
        .background(darkModeEnabled ? vm.tempExportDarkMode != darkModeEnabled ? Color.white : Color.black :
                        vm.tempExportDarkMode != darkModeEnabled ? Color.black : Color.white)
    }
}



struct TwentyGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false


    var body: some View {
        
        VStack(alignment: .center, spacing: vm.globalSpacing) {
            
            // 5x1 row
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(4).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 720, height: 720)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(8).dropFirst(4), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 720, height: 720)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(12).dropFirst(8), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 720, height: 720)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(16).dropFirst(12), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 720, height: 720)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(16), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 720, height: 720)*/
                .aspectRatio(1, contentMode: .fill)
            }


            
            
            
        }
        .frame(width: 3366/*, height: 1518*/)
        .padding(72)
        .background(darkModeEnabled ? vm.tempExportDarkMode != darkModeEnabled ? Color.white : Color.black :
                        vm.tempExportDarkMode != darkModeEnabled ? Color.black : Color.white)
        
        
    }
}





struct TwentyGridExportViewWide: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false


    var body: some View {
        
        VStack(alignment: .center, spacing: vm.globalSpacing) {
            
            // 5x1 row
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(15).dropFirst(10), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(15), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            
            
            
        }
        .frame(width: 3366/*, height: 1518*/)
        .padding(72)
        .background(darkModeEnabled ? vm.tempExportDarkMode != darkModeEnabled ? Color.white : Color.black :
                        vm.tempExportDarkMode != darkModeEnabled ? Color.black : Color.white)
        
        
    }
}


struct TwentyFiveGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
    @AppStorage("appColorTheme") private var darkModeEnabled = false


    var body: some View {
        
        VStack(alignment: .center, spacing: vm.globalSpacing) {
            
            // 5x1 row
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(15).dropFirst(10), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(20).dropFirst(15), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(25).dropFirst(20), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            
            
            
        }
        .frame(width: 3366/*, height: 1518*/)
        .padding(72)
        .background(darkModeEnabled ? vm.tempExportDarkMode != darkModeEnabled ? Color.white : Color.black :
                        vm.tempExportDarkMode != darkModeEnabled ? Color.black : Color.white)
        
        
    }
}
