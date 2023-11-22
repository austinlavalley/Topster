//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import SwiftUI



struct RenderView: View {
    @EnvironmentObject private var vm: FortyScrollGridViewModel
    
//    let album: Album
    
    @State private var snapshot: UIImage?
    
    var body: some View {
        VStack(spacing: 24) {
            if let image = snapshot {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                
                ShareLink(
                    item: Image(uiImage: snapshot!),
                    preview: SharePreview("40 Album Grid", image: Image(uiImage: snapshot!), icon: sharePreview)
                )
            }
        }
        .onAppear {
            generateSnapshot()
        }
    }
    
    var sharePreview: some Transferable {
        Image(systemName: "text.book.closed.fill")
    }
}


extension RenderView {
    func generateSnapshot() {
        Task {
            //            let renderer = await ImageRenderer(content: RenderView(album: album))
            let renderer = await ImageRenderer(content:
//                FortyScrollGridMaster(start: 0, end: 5, size: 144, squareColor: .secondary)
                FortyGridExportView()
//                GridContent()
                .environmentObject(vm)
            )
            if let image = await renderer.uiImage {
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
