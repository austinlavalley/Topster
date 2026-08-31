//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import Photos
import SwiftUI


struct RenderView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    @Environment(\.presentationMode) var presentationMode

    
    @State private var snapshot: UIImage?
    
    
    @State var showLoading = true
    /// Text for the toast. Nil hides it. Holds a message rather than a flag so a
    /// failed or denied save can say so instead of silently doing nothing.
    @State private var saveMessage: String?
    
    
    
    var body: some View {
        
        VStack {
            ZStack {
                VStack(spacing: 24) {
                    
                    VStack {
                        HStack {
                            // A menu rather than a confirmation dialog: this is one
                            // toggle, and a full modal sheet for it was heavy. Both
                            // buttons now carry their own chrome, which they need to
                            // read as controls against the floating bars in iOS 26.
                            Menu {
                                Button(vm.tempExportDarkMode ? "Light background" : "Dark background") {
                                    vm.tempExportDarkMode.toggle()
                                    generateSnapshot()
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3.bold())
                                    .frame(width: 44, height: 44)
                                    .background(.regularMaterial, in: Circle())
                            }
                            // Tint on the control rather than inside the label, so the
                            // icons stay grey instead of picking up the accent colour.
                            // The artwork should be the loudest thing on this sheet.
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Background options")
                            .accessibilityIdentifier("export-options")

                            Spacer()

                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title3.bold())
                                    .frame(width: 44, height: 44)
                                    .background(.regularMaterial, in: Circle())
                            }
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Close")
                            .accessibilityIdentifier("export-close")
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
                                    saveToPhotos(snapshot)
                                }
                                .buttonStyle(DefaultPrimary())
                                .accessibilityIdentifier("save-to-photos")
                            }
                        }.padding()
                    }
                }
                
                
                if let saveMessage {
                    VStack {
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        // Sized to its text rather than fixed, since the permission
                        // message is longer than the success one. Capped so it stays a
                        // pill instead of stretching the full width of the screen.
                        Text(saveMessage)
                            .foregroundColor(.white)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(minWidth: 240)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.65))
                            )
                            .frame(maxWidth: 320)
                            .padding()
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
                Analytics.track(.exportPreviewed(
                    layout: vm.activeGridType.rawValue,
                    filled: vm.FortyGridDict.values.compactMap { entry in entry }.count))
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
            
            

        }

    }
    
    var sharePreview: some Transferable {
        Image(systemName: "text.book.closed.fill")
    }
}





extension RenderView {

    /// Writes the grid to the camera roll and only then says so.
    ///
    /// The old call passed nil for the completion target, so nothing ever reported
    /// back and the toast fired on the button tap. On a first save that put "Grid
    /// saved to camera roll" underneath the permission prompt, before the user had
    /// agreed to anything.
    func saveToPhotos(_ image: UIImage) {
        let layout = vm.activeGridType.rawValue

        // Fired on the tap, before the permission prompt, so the three ways to
        // leave the sheet without an image stay distinguishable.
        Analytics.track(.exportSaveAttempted(layout: layout))

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                show("Topster needs permission to add to Photos. You can change that in Settings.")
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { saved, _ in
                if saved {
                    Analytics.track(.exportSaved(layout: layout))
                }
                show(saved ? "Grid saved to camera roll" : "Couldn't save the grid. Try again.")
            }
        }
    }

    private func show(_ message: String) {
        DispatchQueue.main.async {
            withAnimation { saveMessage = message }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { saveMessage = nil }
            }
        }
    }

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
            case .fortyTwo:
                FortyTwoGridExportView()
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
            
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0).allSatisfy({ $0.value == nil }) {
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
            }
            
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(10).dropFirst(5).allSatisfy({ $0.value == nil }) {
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
            }
            
            
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(16).dropFirst(10).allSatisfy({ $0.value == nil }) {
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
            }
            
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(22).dropFirst(16).allSatisfy({ $0.value == nil }) {
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
            }
            
            
            
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(32).dropFirst(22).allSatisfy({ $0.value == nil }) {
                
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
            }
                
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(42).dropFirst(32).allSatisfy({ $0.value == nil }) {
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
