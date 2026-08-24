//
//  InternetImage.swift
//  Topster
//
//  Created by Austin Lavalley on 11/13/23.
//

import SwiftUI


/// URLs Last.fm has stopped serving.
///
/// `InternetImage` cannot remember this in `@State`, because `RenderView` builds a
/// fresh `ExportView` for every `ImageRenderer` pass. A 404 discovered during one
/// render lands on a view that has already been discarded, so the next render starts
/// from scratch and shows a grey box forever. Keeping it here survives those passes,
/// which is what lets the second render draw the placeholder instead.
enum DeadCoverRegistry {

    private static let lock = NSLock()
    private static var dead: Set<String> = []

    static func isDead(_ url: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return dead.contains(url)
    }

    static func mark(_ url: String) {
        lock.lock()
        defer { lock.unlock() }
        dead.insert(url)
    }
}


/// Drawn in place of cover art when Last.fm has none on file for an album.
///
/// Deliberately quiet, because this also renders into exported grids by way of
/// `AlbumSquare`. Set `showsLabel` only for on-screen views that never get exported.
struct NoCoverPlaceholder: View {
    var showsLabel = false

    var body: some View {
        // Sized off the cell rather than a fixed font size. The interactive grid draws
        // these around 118pt, but ImageRenderer draws the export version several times
        // larger, and a fixed .title3 icon vanished to a speck on a grey field there.
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)

            ZStack {
                Rectangle().fill(.secondary.opacity(0.35))

                VStack(spacing: side * 0.05) {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: side * 0.3, height: side * 0.3)
                        .foregroundStyle(.secondary)

                    if showsLabel {
                        Text("No cover art")
                            .font(.system(size: max(9, side * 0.08)))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}


struct InternetImage<Content: View>: View {
    var url: String
    
    @State private var image: UIImage?
    @State private var coverIsGone = false

    @ViewBuilder var content: (Image) -> Content
    
    init(url: String, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
    }

    /// Nil when Last.fm gave us an empty string, which it does often. Previously
    /// that fell into `guard let url = URL(string: url) else { return }`, set no
    /// state, and left a grey rectangle that would never resolve.
    private var resolvedURL: URL? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
    

    var body: some View {
        VStack {
            if let image = image {
                content(Image(uiImage: image))
            } else if resolvedURL == nil || coverIsGone || DeadCoverRegistry.isDead(url) {
                // Either Last.fm never had art for this album, or the URL it gave us
                // is dead. Both are permanent and both look the same to the user.
                NoCoverPlaceholder()
            } else {
                Rectangle().fill(.secondary)
                    .onAppear { loadImage() }
            }
        }
    }

    
    private func loadImage() {
        guard let url = resolvedURL else { return }
        
        let urlRequest = URLRequest(url: url)
        
        if let cachedResponse = URLCache.shared.cachedResponse(for: urlRequest),
           let image = UIImage(data: cachedResponse.data) {
            self.image = image
        } else {
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let data = data, let response = response, let image = UIImage(data: data) {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: urlRequest)
                    DispatchQueue.main.async {
                        self.image = image
                    }
                    return
                }

                // The server answered and what came back is not a usable image: a 404,
                // a 5xx, or a 200 carrying something that is not decodable. None of
                // that improves on a retry, so record it and draw the placeholder.
                //
                // A nil response means the request never completed at all, which does
                // get better on a retry. Those are left alone so the placeholder keeps
                // its onAppear retry, which is what the export's second render pass
                // relies on to pick up covers that were still in flight.
                if response != nil {
                    DeadCoverRegistry.mark(self.url)
                    DispatchQueue.main.async {
                        self.coverIsGone = true
                    }
                }
            }.resume()
        }
    }
}

struct InternetImage_Previews: PreviewProvider
{
    static var previews: some View
    {
        InternetImage(url: "https://lastfm-img.freetls.fastly.net/i/u/174s/62ee1cffdde64d1e9a3462c307f83bfd.png") { image in
            image
                .resizable()
        }
    }
}
