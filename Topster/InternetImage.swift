//
//  InternetImage.swift
//  Topster
//
//  Created by Austin Lavalley on 11/13/23.
//

import SwiftUI


/// URLs Last.fm has stopped serving.
///
/// This cannot live in view state, because `RenderView` builds a fresh `ExportView`
/// for every `ImageRenderer` pass. A 404 discovered during one render lands on a
/// view that has already been discarded, so the next render starts from scratch and
/// draws a grey box forever. Keeping it here survives those passes.
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


/// Decoded covers held in memory, shared by every view that draws one.
///
/// `InternetImage` answers from its body synchronously so the export can render on
/// its first pass. Without this, a 42 cell grid would go to the on-disk store of
/// `URLCache` once per cell per layout pass.
enum CoverMemoryCache {

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 150
        return cache
    }()

    static func image(for url: String) -> UIImage? {
        guard !url.isEmpty else { return nil }
        return cache.object(forKey: url as NSString)
    }

    static func store(_ image: UIImage, for url: String) {
        guard !url.isEmpty else { return }
        cache.setObject(image, forKey: url as NSString)
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


/// The one loader every cover in the app goes through.
///
/// There were two of these for two years. `AsyncAlbumSquare` was written in November
/// 2023 specifically to avoid this view, because replacing an album in a grid slot
/// left the previous album's cover on screen. That is fixed here rather than avoided,
/// so the grid and the export can no longer disagree about what a cover looks like.
struct InternetImage<Content: View>: View {

    var url: String

    /// Set true for on-screen views. The export leaves it false, because a spinner
    /// frozen mid-rotation is not something to bake into an image someone shares.
    var showsProgressWhileLoading = false

    /// A loaded image together with the URL it came from.
    ///
    /// The pairing is the fix for the 2023 bug. SwiftUI reuses a view when the album
    /// in a slot changes, so bare `@State` survives the change and the body happily
    /// renders the previous album's cover. Comparing the stored URL against the
    /// current one makes a stale image impossible to display.
    @State private var loaded: LoadedCover?

    @ViewBuilder var content: (Image) -> Content

    init(url: String,
         showsProgressWhileLoading: Bool = false,
         @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.showsProgressWhileLoading = showsProgressWhileLoading
        self.content = content
    }

    private struct LoadedCover {
        let url: String
        let image: UIImage
    }

    /// Nil when Last.fm gave us an empty string, which it does for a large share of
    /// albums. `URL(string: "")` is nil, and a nil URL is what used to leave cells
    /// spinning forever with no error to report.
    private var resolvedURL: URL? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    /// An image available without waiting, checked cheapest first.
    ///
    /// Being synchronous is what lets the export render correctly on its first
    /// `ImageRenderer` pass. `.task` does not run in a detached render, so the body
    /// has to be able to answer on its own.
    private var immediateImage: UIImage? {
        if let loaded, loaded.url == url { return loaded.image }
        if let remembered = CoverMemoryCache.image(for: url) { return remembered }
        if let archived = CoverArchive.image(for: url) { return archived }

        guard let resolved = resolvedURL,
              let cached = URLCache.shared.cachedResponse(for: URLRequest(url: resolved)),
              let image = UIImage(data: cached.data)
        else { return nil }

        CoverMemoryCache.store(image, for: url)
        return image
    }

    var body: some View {
        VStack {
            if let image = immediateImage {
                content(Image(uiImage: image))
            } else if resolvedURL == nil || DeadCoverRegistry.isDead(url) {
                NoCoverPlaceholder()
            } else if showsProgressWhileLoading {
                ZStack {
                    Rectangle().fill(.secondary.opacity(0.25))
                    ProgressView()
                }
            } else {
                Rectangle().fill(.secondary.opacity(0.25))
            }
        }
        // Runs on first appearance and again whenever the slot's album changes, which
        // is the refresh behaviour onAppear could never provide. Cancels when a cell
        // scrolls away and restarts when it comes back.
        .task(id: url) { await load() }
    }

    private func load() async {
        guard immediateImage == nil, let resolved = resolvedURL else { return }

        let request = URLRequest(url: resolved)
        let requested = url

        // One lost request used to leave a cell showing a placeholder for the rest of
        // the session, because nothing ever tried again. Reported against the live
        // 1.5.0 build: two covers of six failed on launch and stayed failed until the
        // grid was reopened.
        for attempt in 0..<3 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 400_000_000)
            }

            guard !Task.isCancelled else { return }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let image = UIImage(data: data) {
                    URLCache.shared.storeCachedResponse(
                        CachedURLResponse(response: response, data: data), for: request)
                    CoverMemoryCache.store(image, for: requested)

                    // The slot may have been filled with a different album while this
                    // was in flight. Dropping a late arrival is what stops it painting
                    // over a newer cover.
                    guard !Task.isCancelled, requested == url else { return }

                    loaded = LoadedCover(url: requested, image: image)
                    return
                }

                // The server answered and what came back is not an image: a 404, a
                // 5xx, or a 200 carrying something undecodable. Retrying will not
                // change that answer.
                DeadCoverRegistry.mark(requested)
                return

            } catch {
                // The request never completed at all. Worth another go.
                continue
            }
        }
    }
}


struct InternetImage_Previews: PreviewProvider
{
    static var previews: some View
    {
        InternetImage(url: "https://lastfm-img.freetls.fastly.net/i/u/300x300/62ee1cffdde64d1e9a3462c307f83bfd.png") { image in
            image
                .resizable()
        }
    }
}
