//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import SwiftUI

// An example view to render
struct RenderView: View {
    let image: Image

    var body: some View {
            image
                .frame(width: 240, height: 240)
    }
}

struct ImageRender: View {
    
    @State private var image = Image("localAlbum")
    
    @State private var renderedImage = Image(systemName: "photo")
    @Environment(\.displayScale) var displayScale

    var body: some View {
        VStack {
            
            // what being displayed is actually the rendered image, the RenderView doesn't actually exist
            renderedImage

            
            // export really just means pulling up the share menu on the displayed image
            ShareLink("Export", item: renderedImage, preview: SharePreview(Text("Shared image"), image: renderedImage))

            
            Button("re render") { render() }
            
        }
        
        // on first view OR when it is changed, rerender the image
//        .onChange(of: text) { _ in render() }
        .onAppear { render() }
    }

    
    
    // func for rendering
    @MainActor func render() {
        let renderer = ImageRenderer(content: RenderView(image: image))

        // make sure and use the correct display scale for this device
        renderer.scale = displayScale

        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

struct ImageRender_Previews: PreviewProvider {
    static var previews: some View {
        ImageRender()
    }
}
