//
//  UsageCounters.swift
//  Topster
//

import Foundation

/// The milestones a person passes through once per install, ever.
///
/// Raw values are the analytics property, so they are a fixed vocabulary
/// rather than free text, and renaming one orphans a funnel.
enum ActivationMilestone: String, CaseIterable {
    case firstAlbumPlaced = "first_album_placed"
    case firstGridSaved = "first_grid_saved"
    case firstExportSaved = "first_export_saved"
}


/// Lifetime, on-device counters. Two jobs.
///
/// First, they become user properties, so every event is segmentable by how
/// experienced the person sending it is. Without them a 40 second first
/// session and a 40 second twentieth session are the same row.
///
/// Second, the app reads them itself. Onboarding help has to know it is
/// someone's first run, and that decision cannot wait on a dashboard.
///
/// Counts only. Nothing here describes what was placed, saved, or searched.
struct UsageCounters {

    private enum Key {
        static let installDate = "usage.installDate"
        static let sessionCount = "usage.sessionCount"
        static let albumsPlaced = "usage.albumsPlaced"
        static let gridsSaved = "usage.gridsSaved"
        static let exports = "usage.exports"
        static func milestone(_ m: ActivationMilestone) -> String { "usage.milestone.\(m.rawValue)" }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    static let shared = UsageCounters()

    /// Call once at launch, before any event is sent. Stamps the install date
    /// the first time it ever runs and returns the number of this session.
    ///
    /// Installs that predate this build get their install date stamped on the
    /// upgrade launch, so `days_since_install` reads 0 for people who have had
    /// the app for a year. That is a known distortion with a fixed lifetime:
    /// it disappears once every reporting window starts after this release.
    @discardableResult
    func recordLaunch() -> Int {
        if defaults.object(forKey: Key.installDate) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: Key.installDate)
        }

        let next = sessionCount + 1
        defaults.set(next, forKey: Key.sessionCount)
        return next
    }

    var installDate: Date {
        let stamp = defaults.double(forKey: Key.installDate)
        return stamp > 0 ? Date(timeIntervalSince1970: stamp) : Date()
    }

    var secondsSinceInstall: Int {
        max(0, Int(Date().timeIntervalSince(installDate)))
    }

    var daysSinceInstall: Int {
        secondsSinceInstall / 86_400
    }

    var sessionCount: Int { defaults.integer(forKey: Key.sessionCount) }
    var albumsPlaced: Int { defaults.integer(forKey: Key.albumsPlaced) }
    var gridsSaved: Int { defaults.integer(forKey: Key.gridsSaved) }
    var exports: Int { defaults.integer(forKey: Key.exports) }

    func recordAlbumPlaced() { defaults.set(albumsPlaced + 1, forKey: Key.albumsPlaced) }
    func recordGridSaved() { defaults.set(gridsSaved + 1, forKey: Key.gridsSaved) }
    func recordExport() { defaults.set(exports + 1, forKey: Key.exports) }

    func hasPassed(_ milestone: ActivationMilestone) -> Bool {
        defaults.bool(forKey: Key.milestone(milestone))
    }

    /// True exactly once per install, on the first call for that milestone.
    /// Every later call returns false, so the caller can send the event
    /// unconditionally and trust it fires once.
    func claim(_ milestone: ActivationMilestone) -> Bool {
        guard !hasPassed(milestone) else { return false }
        defaults.set(true, forKey: Key.milestone(milestone))
        return true
    }

    /// Test seam. Wipes every key this type owns from the backing store.
    func reset() {
        let keys = [Key.installDate, Key.sessionCount, Key.albumsPlaced,
                    Key.gridsSaved, Key.exports]
            + ActivationMilestone.allCases.map(Key.milestone)
        keys.forEach { key in defaults.removeObject(forKey: key) }
    }
}
