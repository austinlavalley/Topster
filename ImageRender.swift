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
    let album: Album

    var body: some View {
//        VStack {
            Text(album.artist)
            Text(album.name)
            Text(album.image.first(where: { $0.size == "large"})?.text ?? "").frame(width: 360)
            
            AsyncImage(url: URL(string: album.image.first(where: { $0.size == "large" })?.text ?? "")) { phase in
                switch phase {
                case .empty:
                    Color.purple.opacity(0.1)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Image(systemName: "exclamationmark.icloud")
                        .resizable()
                        .scaledToFit()
                @unknown default:
                    Image(systemName: "exclamationmark.icloud")
                }
            }
            .frame(width: 240, height: 240)
            .cornerRadius(20)
                        
            image
                .frame(width: 240, height: 240)
                .cornerRadius(20)
//        }
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

            // RENDERVIEW IS WORKING FINE, IT'S THE IMAGERENDERER THAT CANNOT CONVERT THE ASYNCIMAGES INTO AN IMAGE
            
            
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
        let renderer = ImageRenderer(content: RenderView(image: image, album: Album(name: "American Heartbreak", artist: "Zach Bryan", url: "https://www.last.fm/music/Zach+Bryan/American+Heartbreak", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("extralarge"))], streamable: "0", mbid: "")))

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
