//
//  CoverArchive.swift
//  Topster
//
//  Created by Austin Lavalley on 8/24/26.
//

import CryptoKit
import UIKit


/// Local copies of the cover art belonging to saved grids.
///
/// About 4% of the cover URLs Last.fm hands out eventually stop resolving, so a grid
/// built in 2024 loses a cover here and there just by existing. Keeping a copy on
/// disk means a saved grid renders the same way forever, offline, with the API down,
/// or after Last.fm drops the image.
///
/// Archived copies are downsampled to 174px JPEG, roughly 15 to 25 KB each against
/// the 190 KB of the 300px art the grid displays. A full 42 album grid costs about
/// 1 MB. They are written from whatever is already in `URLCache`, so saving a grid
/// does not trigger a second round of downloads.
enum CoverArchive {

    private static let longestSide: CGFloat = 174
    private static let jpegQuality: CGFloat = 0.85

    /// Decoded archives, so a scrolling grid is not hitting the disk per cell.
    private static let decoded: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        return cache
    }()


    // MARK: - Locations

    private static var directory: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else { return nil }

        let dir = base.appendingPathComponent("CoverArchive", isDirectory: true)

        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }

    /// Named by a hash of the URL so the filename is stable, filesystem safe, and
    /// does not depend on Last.fm's path format staying the same.
    private static func filename(for url: String) -> String {
        let digest = SHA256.hash(data: Data(url.utf8))
        return digest.map { byte in String(format: "%02x", byte) }.joined() + ".jpg"
    }

    private static func fileURL(for url: String) -> URL? {
        guard !url.isEmpty, let directory else { return nil }
        return directory.appendingPathComponent(filename(for: url))
    }


    // MARK: - Reading

    /// The archived cover, if one was kept for this URL.
    ///
    /// Callers should check this before going to the network. For a saved grid the
    /// archive is the authoritative copy: album art does not change, so refetching
    /// gains nothing and costs a round trip that fails when offline.
    static func image(for url: String) -> UIImage? {
        guard !url.isEmpty else { return nil }

        let key = url as NSString
        if let hit = decoded.object(forKey: key) { return hit }

        guard let file = fileURL(for: url),
              let data = try? Data(contentsOf: file),
              let image = UIImage(data: data)
        else { return nil }

        decoded.setObject(image, forKey: key)
        return image
    }


    // MARK: - Writing

    /// Keeps a copy of every cover in `albums` that is already in `URLCache`.
    ///
    /// Covers that were never loaded are skipped rather than fetched. Anything on
    /// screen when a grid is saved is in the cache by definition, and an album whose
    /// art never loaded has nothing worth keeping.
    static func archive(_ albums: [Album]) {
        DispatchQueue.global(qos: .utility).async {
            for album in albums {
                guard let coverURL = album.coverURL else { continue }

                let key = coverURL.absoluteString
                guard let file = fileURL(for: key),
                      !FileManager.default.fileExists(atPath: file.path)
                else { continue }

                guard let cached = URLCache.shared.cachedResponse(for: URLRequest(url: coverURL)),
                      let image = UIImage(data: cached.data)
                else { continue }

                guard let data = downsampled(image).jpegData(compressionQuality: jpegQuality)
                else { continue }

                try? data.write(to: file, options: .atomic)
            }
        }
    }

    private static func downsampled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > longestSide else { return image }

        let ratio = longestSide / longest
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }


    // MARK: - Cleanup

    /// Deletes archives no saved grid refers to any more.
    ///
    /// Call after removing a grid. Covers shared with another saved grid survive,
    /// which is why this takes the full keep set rather than a delete list.
    static func prune(keeping keep: Set<String>) {
        DispatchQueue.global(qos: .utility).async {
            guard let directory,
                  let files = try? FileManager.default.contentsOfDirectory(at: directory,
                                                                           includingPropertiesForKeys: nil)
            else { return }

            let wanted = Set(keep.compactMap { url in fileURL(for: url)?.lastPathComponent })

            for file in files where !wanted.contains(file.lastPathComponent) {
                try? FileManager.default.removeItem(at: file)
            }

            decoded.removeAllObjects()
        }
    }

    /// Bytes currently on disk, for reporting.
    static func sizeOnDisk() -> Int {
        guard let directory,
              let files = try? FileManager.default.contentsOfDirectory(at: directory,
                                                                       includingPropertiesForKeys: [.fileSizeKey])
        else { return 0 }

        return files.reduce(0) { total, file in
            total + ((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }
}
