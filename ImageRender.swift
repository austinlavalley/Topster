//
//  ImageRenderer.swift
//  Topster
//
//  Created by Austin Lavalley on 11/11/23.
//

import SwiftUI



struct RenderView: View {
    let album: Album
    
    @State private var snapshot: UIImage?
    
    var body: some View {
        VStack(spacing: 24) {
            if let image = snapshot {
                Image(uiImage: image)
                
                ShareLink(
                    item: Image(uiImage: snapshot!),
                    preview: SharePreview(album.name, image: Image(uiImage: snapshot!), icon: sharePreview)
                )
            }
            
            InternetImage(url: "https://lastfm.freetls.fastly.net/i/u/300x300/07c3b7f594f5513c5f07fa7f8fb81787.png") { image in
                image
                    .resizable()
                    .frame(width: 240, height: 240)
                    .cornerRadius(24)
            }
            
            Button(action: generateSnapshot) {
                Text("Create snapshot")
            }.buttonStyle(.bordered)
        }
    }
    
    var sharePreview: some Transferable {
        Image(systemName: "text.book.closed.fill")
    }
}


extension RenderView {
    func generateSnapshot() {
        Task {
            let renderer = await ImageRenderer(content: RenderView(album: Album(name: "American Heartbreak", artist: "Zach Bryan", url: "https://www.last.fm/music/Zach+Bryan/American+Heartbreak", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("extralarge"))], streamable: "0", mbid: "")))
            if let image = await renderer.uiImage {
                self.snapshot = image
            }
        }
    }
}






struct ImageRender_Previews: PreviewProvider {
    static var previews: some View {
        RenderView(album: Album(name: "American Heartbreak", artist: "Zach Bryan", url: "https://www.last.fm/music/Zach+Bryan/American+Heartbreak", image: [Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/34s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("small")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/64s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("medium")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/174s/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("large")), Topster.AlbumImage(text: Optional("https://lastfm.freetls.fastly.net/i/u/300x300/07c3b7f594f5513c5f07fa7f8fb81787.png"), size: Optional("extralarge"))], streamable: "0", mbid: ""))
    }
}
