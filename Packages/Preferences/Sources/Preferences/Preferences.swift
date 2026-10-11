//
//  Preferences.swift
//  Preferences
//
//  App-wide settings store. One instance lives for the app's lifetime (owned
//  by the composition root) and is injected wherever region or language is
//  needed. Persists to UserDefaults so choices survive app launches.
//

import Foundation
import Domain

@Observable
@MainActor
public final class Preferences {

    /// The user's streaming region (controls which providers are shown).
    public var region: Region {
        didSet { defaults.set(region.code, forKey: Self.regionKey) }
    }

    /// The user's preferred language (controls TMDB's localised output:
    /// titles, overviews, poster art).
    public var language: Language {
        didSet { defaults.set(language.code, forKey: Self.languageKey) }
    }

    /// The streaming services the user pays for. Persisted as a JSON-encoded
    /// sorted `[Int]` in UserDefaults so values are deterministic across runs
    /// (useful for debugging and for the "did the user change anything?" check
    /// some screens may want).
    ///
    /// No region scoping — the feature's mental model is "I have a Netflix
    /// account, my VPN handles the rest." If multi-region account tagging
    /// becomes a real need, this would graduate to a `Set<Subscription>` value.
    public var subscribedProviderIDs: Set<ProviderID> {
        didSet { persistSubscribedProviders() }
    }

    /// A value type snapshot of both axes. Use this as the `id:` argument of
    /// `.task(id:)` in any view that needs to re-fire a query when either
    /// setting changes.
    public struct Snapshot: Hashable, Sendable {
        public let region: Region
        public let language: Language
        public init(region: Region, language: Language) {
            self.region = region
            self.language = language
        }
    }

    public var snapshot: Snapshot { Snapshot(region: region, language: language) }

    private let defaults: UserDefaults

    private static let regionKey               = "settings.region.code"
    private static let languageKey             = "settings.language.code"
    private static let subscribedProvidersKey  = "settings.subscribedProviders.ids"

    public init(
        defaultRegion: Region = .currentLocale,
        defaultLanguage: Language = .currentLocale,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults

        if let stored = defaults.string(forKey: Self.regionKey), !stored.isEmpty {
            self.region = Region(code: stored)
        } else {
            self.region = defaultRegion
        }

        // Only languages the picker still offers: one stored by an older build
        // (e.g. French, before the list was cut to translated languages) would
        // pair localized content with an untranslated interface.
        if let stored = defaults.string(forKey: Self.languageKey),
           let known = Language.allKnown.first(where: { $0.code == stored }) {
            self.language = known
        } else {
            self.language = defaultLanguage
        }

        self.subscribedProviderIDs = Self.loadSubscribedProviders(from: defaults)
    }

    // MARK: - Subscribed providers persistence
    //
    // `Set<ProviderID>` doesn't survive UserDefaults' plist constraints
    // directly, so we serialise to a JSON-encoded `[Int]`. Sorted on write
    // for deterministic on-disk values; sorting is cheap at this size
    // (subscriptions are O(10), not O(1000)).

    private func persistSubscribedProviders() {
        let raw = subscribedProviderIDs.map(\.rawValue).sorted()
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: Self.subscribedProvidersKey)
        }
    }

    /// Reads the persisted set, falling back to empty on any decode failure.
    /// Graceful fallback is the right call here: if the stored value is
    /// corrupt, the user just sees an empty subscriptions list and can
    /// re-pick — preferable to a crash on launch.
    private static func loadSubscribedProviders(from defaults: UserDefaults) -> Set<ProviderID> {
        guard let data = defaults.data(forKey: Self.subscribedProvidersKey),
              let raw = try? JSONDecoder().decode([Int].self, from: data)
        else { return [] }
        return Set(raw.map(ProviderID.init))
    }
}
