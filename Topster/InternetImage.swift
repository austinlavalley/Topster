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

    /// Bumped when a fetch marks this cover dead, so the body re-evaluates and
    /// the placeholder appears immediately instead of on the next unrelated
    /// re-render. The registry itself stays the source of truth.
    @State private var deadCoverVersion = 0

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

    /// Reads deadCoverVersion so the body re-evaluates when a fetch marks this
    /// cover dead mid-flight; the registry stays the source of truth.
    private var isConfirmedDead: Bool {
        _ = deadCoverVersion
        return DeadCoverRegistry.isDead(url)
    }

    var body: some View {
        VStack {
            if let image = immediateImage {
                content(Image(uiImage: image))
            } else if resolvedURL == nil || isConfirmedDead {
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

        let requested = url

        // The spinner must always mean "still trying". A cover the network
        // cannot deliver right now is retried on a slowing schedule for as
        // long as its cell is on screen; the task dies with the cell. Before
        // this loop, exhausting the fetcher's attempts left the spinner up
        // over nothing, and a cover the CDN refused for a few minutes needed
        // force-quits and view-hopping to ever load. Observed on device
        // 28 Aug 2026.
        var pauseSeconds: UInt64 = 5
        while !Task.isCancelled {
            switch await CoverFetcher.fetch(resolved) {
            case let .image(image, _):
                CoverMemoryCache.store(image, for: requested)

                // The slot may have been filled with a different album while
                // this was in flight. Dropping a late arrival is what stops it
                // painting over a newer cover.
                guard !Task.isCancelled, requested == url else { return }
                loaded = LoadedCover(url: requested, image: image)
                return

            case .gone:
                // The server answered definitively that this cover does not
                // exist; only that verdict shows the placeholder. The bump
                // exists because marking the registry alone does not make
                // SwiftUI re-evaluate the body.
                DeadCoverRegistry.mark(requested)
                deadCoverVersion += 1
                return

            case .unreachable:
                try? await Task.sleep(nanoseconds: pauseSeconds * 1_000_000_000)
                pauseSeconds = min(pauseSeconds * 2, 240)
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
