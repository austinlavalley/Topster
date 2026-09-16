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
    /// What the Save to Photos button is showing about the last save. Set from
    /// the Photos callbacks, never from the tap, so a first save does not say
    /// "saved" underneath the permission prompt.
    @State private var savePhase = ConfirmPhase.idle
    /// Photos access was refused. Needs a decision, so it is an alert with a
    /// way to Settings rather than a button state.
    @State private var showPhotosDenied = false
    
    
    
    var body: some View {
        
        VStack {
            ZStack {
                VStack(spacing: 24) {
                    
                    VStack {
                        HStack {
                            // The options used to hide behind a slider icon up here.
                            // With two of them they sit on the screen instead, next to
                            // the preview they change. The close button keeps its own
                            // chrome so it reads as a control against the floating
                            // bars in iOS 26.
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

                        ExportOptions()
                            .padding(.horizontal)

                        // export buttons
                        VStack {
                            ShareLink(
                                item: Image(uiImage: snapshot!),
                                preview: SharePreview((vm.currentActiveGrid != nil) ? "Grid #\(vm.currentActiveGrid ?? 0)" : "Unsaved Grid", image: Image(uiImage: snapshot!), icon: sharePreview)
                            )
                            .buttonStyle(DefaultSecondary())
                            
                            if let snapshot = snapshot {
                                ConfirmingButton(title: "Save to Photos",
                                                 confirmedTitle: "Saved to Photos",
                                                 failedTitle: "Couldn't save. Try again",
                                                 phase: $savePhase) {
                                    saveToPhotos(snapshot)
                                }
                                .accessibilityIdentifier("save-to-photos")
                            }
                        }.padding()
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
            .onChange(of: vm.tempExportDarkMode, { _, _ in
                generateSnapshot()
            })
            .onChange(of: vm.exportLabels, { _, _ in
                generateSnapshot()
            })
            .alert("Photos access is off", isPresented: $showPhotosDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Topster needs permission to add to your Photos library. You can turn it on in Settings.")
            }
            
            

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
    /// back and the confirmation fired on the button tap. On a first save that put
    /// "Grid saved to camera roll" underneath the permission prompt, before the
    /// user had agreed to anything. Every outcome now lands on the main thread
    /// from the Photos callback: saved and failed as button states, denied as
    /// an alert because it needs a decision.
    func saveToPhotos(_ image: UIImage) {
        let layout = vm.activeGridType.rawValue
        let labels = vm.exportLabels.rawValue
        let background = vm.tempExportDarkMode ? "dark" : "light"

        // Fired on the tap, before the permission prompt, so the three ways to
        // leave the sheet without an image stay distinguishable.
        Analytics.track(.exportSaveAttempted(layout: layout))

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { showPhotosDenied = true }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { saved, _ in
                if saved {
                    Analytics.track(.exportSaved(layout: layout, labels: labels, background: background))
                }
                DispatchQueue.main.async { savePhase = saved ? .confirmed : .failed }
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
        HStack(alignment: .top, spacing: 0) {
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

            // Ideal height only. A top-aligned HStack proposes its tallest
            // child's height to every child, and the layout views size their
            // tiles with aspectRatio(.fill), so a sidebar taller than the grid
            // once inflated the ten-across rows past their columns.
            .fixedSize(horizontal: false, vertical: true)

            if vm.exportLabels == .list {
                ExportSidebar()
            }
        }
        .overlay(alignment: .bottom) {
            ExportWatermark()
        }
        // Painted here rather than inside each layout view, so the sidebar and
        // the grid share one ground with no seam between them.
        .background(vm.tempExportDarkMode ? Color.black : Color.white)
    }
}


/// One small line in the bottom margin of every export.
///
/// Grids get posted in places that never say where they came from, so the
/// image itself has to. Austin, 15 Sep 2026: a few pixels that unlock a
/// distribution channel. Sized to sit inside the margin the layouts already
/// leave, so the canvas is the same size with or without it, and muted so
/// it reads as a signature rather than a stamp.
///
/// The icon and the domain, not the app's name: "Topster" on its own leads
/// a search to the web tool, and the icon says at a glance that this came
/// from an app. The icon is drawn at text height as a rounded square, the
/// shape every iOS icon has, so on the light ground it reads as an app icon
/// rather than a dark blot.
struct ExportWatermark: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    /// Printed on every export, so it has to resolve. Registered and pointed
    /// at the App Store listing before the build that carries it ships.
    static let domain = "topster.app"

    /// 36pt on the 3366px canvas is about 11px once the image is posted at
    /// 1080 wide, the smallest that still reads. 26pt was tried and vanished.
    private let size: CGFloat = 36

    var body: some View {
        HStack(spacing: size * 0.4) {
            // Its own image set: the app icon's catalog name loads nil on
            // iOS 26 with a single-size icon set.
            Image("WatermarkIcon")
                .resizable()
                .frame(width: size * 1.15, height: size * 1.15)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            Text("Made with \(Self.domain)")
                .font(.system(size: size, weight: .medium, design: .monospaced))
        }
        .foregroundStyle((vm.tempExportDarkMode ? Color.white : Color.black).opacity(0.45))
        .padding(.bottom, 14)
    }
}


/// The two export options, on the screen rather than behind a menu.
///
/// Segmented rather than toggles because the titles choice has three states,
/// and one control shape for both rows reads as one panel.
struct ExportOptions: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    var body: some View {
        VStack(spacing: 12) {
            row("Background") {
                Picker("Background", selection: $vm.tempExportDarkMode) {
                    Text("Light").tag(false)
                    Text("Dark").tag(true)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("export-background")
            }

            row("Titles") {
                Picker("Titles", selection: $vm.exportLabels) {
                    Text("None").tag(ExportLabels.none)
                    Text("Overlay").tag(ExportLabels.overlay)
                    Text("List").tag(ExportLabels.list)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("export-titles")
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func row<Content: View>(_ label: String, @ViewBuilder control: () -> Content) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            control()
        }
    }
}


/// One cover in the export, with its caption when captions are on.
///
/// Wraps `AlbumSquare` rather than changing it, because the interactive grid
/// draws the same square and must not grow text.
struct ExportTile: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    let album: Album

    var body: some View {
        AlbumSquare(album: album)
            .overlay(alignment: .bottom) {
                if vm.exportLabels == .overlay {
                    // Tiles run from about 670px wide in a five-across row to
                    // 337px in a ten-across row, so the caption scales with the
                    // tile instead of carrying one size.
                    GeometryReader { geo in
                        let size = geo.size.width * 0.055

                        Text(album.exportCaption)
                            .font(.system(size: size, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.horizontal, size * 0.5)
                            .padding(.vertical, size * 0.45)
                            .frame(width: geo.size.width)
                            .background(Color.black.opacity(0.6))
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                    }
                }
            }
    }
}


/// Stacks the sidebar sections so each starts level with its band of rows,
/// pulling later sections up into the slack above them rather than letting
/// the list run past the bottom of the grid. The arithmetic is
/// `ExportList.groupTops`; this is the part that needs the rendered height of
/// each section.
struct RowAlignedColumn: Layout {
    /// Where each section's band starts, in the grid's coordinate space.
    let rowTops: [CGFloat]
    /// The bottom of the grid.
    let floor: CGFloat
    let gap: CGFloat

    private func heights(of subviews: Subviews, width: CGFloat) -> [CGFloat] {
        subviews.map { subview in
            subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width
            ?? subviews.map { subview in subview.sizeThatFits(.unspecified).width }.max()
            ?? 0
        let heights = heights(of: subviews, width: width)
        let tops = ExportList.groupTops(preferred: rowTops, heights: heights, floor: floor, gap: gap)
        let bottom = zip(tops, heights).map { top, height in top + height }.max() ?? 0
        return CGSize(width: width, height: bottom)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let heights = heights(of: subviews, width: bounds.width)
        let tops = ExportList.groupTops(preferred: rowTops, heights: heights, floor: floor, gap: gap)
        for (subview, top) in zip(subviews, tops) {
            subview.place(at: CGPoint(x: bounds.minX, y: bounds.minY + top),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(width: bounds.width, height: nil))
        }
    }
}


/// The numbered list beside the grid, one section per band of rows, each
/// section starting level with its band where the band has the height for it.
struct ExportSidebar: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel

    private var sections: [ExportListSection] {
        let shape = vm.activeGridType.rowShape
        return ExportList.sections(
            groups: ExportList.groups(grid: vm.FortyGridDict, shape: shape),
            rowHeights: ExportList.rowHeights(shape: shape, width: ExportCanvas.width,
                                              spacing: vm.globalSpacing),
            rowsPerSection: vm.activeGridType.rowsPerListSection,
            hidesEmptyRows: vm.activeGridType.hidesEmptyRows,
            spacing: vm.globalSpacing)
    }

    /// The bottom edge of the last drawn band, which the list may not cross.
    private func floor(of sections: [ExportListSection]) -> CGFloat {
        sections.last.map { section in section.top + section.height } ?? 0
    }

    /// The fixed layouts give a row of five 654px for five lines, which 56pt
    /// clears easily, so every section sits level with its row. On the 42
    /// the last band is 654px for twenty lines, which no readable face fits,
    /// so `RowAlignedColumn` starts that section early and ends it on the
    /// grid's bottom edge. The face is chosen so the section above it still
    /// keeps a visible gap: at 36pt the twenty lines reached up and closed
    /// it, and the three sections read as one list; at 32pt they are 969px
    /// tall and the gap under the twelve-line section is about 240px.
    private var fontSize: CGFloat {
        vm.activeGridType == .fortyTwo ? 32 : 56
    }

    /// Right-aligned numbers, so "9." and "10." start their text in the same
    /// column. Monospaced makes the padding exact.
    private func numberWidth(of sections: [ExportListSection]) -> Int {
        String(sections.last?.lines.last?.number ?? 0).count
    }

    var body: some View {
        let sections = sections
        let numberWidth = numberWidth(of: sections)

        if sections.contains(where: { section in !section.lines.isEmpty }) {
            RowAlignedColumn(rowTops: sections.map(\.top), floor: floor(of: sections),
                             gap: vm.globalSpacing) {
                ForEach(sections.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: fontSize * 0.35) {
                        ForEach(sections[index].lines, id: \.number) { line in
                            Text(String(repeating: " ", count: numberWidth - String(line.number).count)
                                 + "\(line.number). \(line.text)")
                                .font(.system(size: fontSize, design: .monospaced))
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            .foregroundStyle(vm.tempExportDarkMode ? Color.white : Color.black)
            .frame(width: 1600, alignment: .topLeading)
            .padding(.leading, 24)
            .padding(.trailing, ExportCanvas.margin)
            .padding(.vertical, ExportCanvas.margin)
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
                        ExportTile(album: album!)
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
                                ExportTile(album: album!)
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
                                ExportTile(album: album!)
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
                                ExportTile(album: album!)
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
                                ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
    


    var body: some View {
        
        VStack(spacing: vm.globalSpacing) {
            
            if !vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0).allSatisfy({ $0.value == nil }) {
                HStack(spacing: vm.globalSpacing) {
                    ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                        if album != nil {
                            ExportTile(album: album!)
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
                            ExportTile(album: album!)
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
                            ExportTile(album: album!)
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
                            ExportTile(album: album!)
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
                            ExportTile(album: album!)
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
                            ExportTile(album: album!)
                        } else {
                            Rectangle().fill(.secondary)
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                }
            }
            
        }
        .frame(width: ExportCanvas.width)
        .padding(ExportCanvas.margin)
    }
}



struct TwentyGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    


    var body: some View {
        
        VStack(alignment: .center, spacing: vm.globalSpacing) {
            
            // 5x1 row
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(4).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 720, height: 720)*/
                .aspectRatio(1, contentMode: .fill)
            }


            
            
            
        }
        .frame(width: ExportCanvas.width)
        .padding(ExportCanvas.margin)
        
        
    }
}





struct TwentyGridExportViewWide: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    


    var body: some View {
        
        VStack(alignment: .center, spacing: vm.globalSpacing) {
            
            // 5x1 row
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            
            
            
        }
        .frame(width: ExportCanvas.width)
        .padding(ExportCanvas.margin)
        
        
    }
}


struct TwentyFiveGridExportView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    


    var body: some View {
        
        VStack(alignment: .center, spacing: vm.globalSpacing) {
            
            // 5x1 row
            HStack(spacing: vm.globalSpacing) {

                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(5).dropFirst(0), id: \.key) { key, album in
                    if album != nil {
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
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
                        ExportTile(album: album!)
                    } else {
                        // if row has no values in it, do not display row in renderview
                        Rectangle().fill(.secondary)
                    }
                } /*.frame(width: 320, height: 320)*/
                .aspectRatio(1, contentMode: .fill)
            }
            
            
            
            
        }
        .frame(width: ExportCanvas.width)
        .padding(ExportCanvas.margin)
        
        
    }
}
