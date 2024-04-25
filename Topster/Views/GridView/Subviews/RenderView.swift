//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import SwiftUI


struct RenderView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
//    @Environment(\.presentationMode) var presentationMode

    
    @State private var snapshot: UIImage?
    
    
    @State var showLoading = true
    @State private var showingSavedToPhotosSuccess = false
    
    
    var body: some View {
        
        ZStack {

            VStack(spacing: 24) {
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
                            preview: SharePreview("40 Album Grid", image: Image(uiImage: snapshot!), icon: sharePreview)
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
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.65))
                            .frame(width: 240, height: 64)
                            .padding()
                        
                        Text("Grid saved to camera roll").foregroundColor(.white).bold()
                    }
                }
            }
            
            if showLoading { LoadingView() }
        }
        
        
        .onAppear {
            generateSnapshot()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                generateSnapshot()
                showLoading = false
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
                FortyGridExportView()
                    .environmentObject(vm)
            )
            
            if let image = renderer.uiImage {
                self.snapshot = image
            }
        }
    }
}





struct RenderView_Previews: PreviewProvider {
    static var previews: some View {
        RenderView()
    }
}


struct LoadingView: View {
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black)
                .opacity(0.75)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                Text("Loading...")
            }
            .background {
                RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .frame(width: 200, height: 200)
            }
            .offset(y: -70)
        }
    }
}









// ACTUAL VIEW THAT IS BEING EXPORTED

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
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 250, height: 250)
            }.frame(width: 1600)
            
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(17).dropFirst(11), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
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
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 200, height: 200)
            }
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(31).dropFirst(24), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
                    } else {
                        Rectangle().fill(.secondary.opacity(0.5))
                    }
                } .frame(width: 200, height: 200)
            }
            
            
            HStack {
                ForEach(vm.FortyGridDict.sorted(by: { $0.key < $1.key }).prefix(40).dropFirst(31), id: \.key) { key, album in
                    if album != nil {
                        AlbumSquare(album: album!)
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
