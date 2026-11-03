//
//  PreferencesTests.swift
//  PreferencesTests
//

import Testing
import Foundation
import Domain
@testable import Preferences

/// Uses an isolated `UserDefaults(suiteName:)` per test so the device's real
/// app defaults aren't touched and tests don't leak state into one another.
@MainActor
@Suite struct SubscribedProvidersPersistenceTests {

    private func makeDefaults() -> UserDefaults {
        let suite = "PreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func emptyByDefault() {
        let prefs = Preferences(defaults: makeDefaults())
        #expect(prefs.subscribedProviderIDs.isEmpty)
    }

    @Test func roundTripPersistsAcrossInstances() {
        let defaults = makeDefaults()
        let prefs = Preferences(defaults: defaults)
        prefs.subscribedProviderIDs = [ProviderID(8), ProviderID(9), ProviderID(337)]

        // A new Preferences reading the same defaults should observe the set.
        let reloaded = Preferences(defaults: defaults)
        #expect(reloaded.subscribedProviderIDs == [ProviderID(8), ProviderID(9), ProviderID(337)])
    }

    @Test func corruptDataFallsBackToEmpty() {
        let defaults = makeDefaults()
        // Write garbage under the key — graceful fallback should yield empty.
        defaults.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: "settings.subscribedProviders.ids")
        let prefs = Preferences(defaults: defaults)
        #expect(prefs.subscribedProviderIDs.isEmpty)
    }
}

@MainActor
@Suite struct LanguagePersistenceTests {

    private func makeDefaults() -> UserDefaults {
        let suite = "PreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func roundTripPersistsAcrossInstances() {
        let defaults = makeDefaults()
        let prefs = Preferences(defaultLanguage: .englishUS, defaults: defaults)
        prefs.language = .spanishES

        #expect(Preferences(defaultLanguage: .englishUS, defaults: defaults).language == .spanishES)
    }

    /// French was offered before the picker was limited to translated
    /// languages; a stored French choice must not survive.
    @Test func languageThePickerNoLongerOffersFallsBackToTheDefault() {
        let defaults = makeDefaults()
        defaults.set("fr-FR", forKey: "settings.language.code")

        let prefs = Preferences(defaultLanguage: .englishUS, defaults: defaults)

        #expect(prefs.language == .englishUS)
    }
}

@MainActor
@Suite struct RegionDefaultTests {

    private func makeDefaults() -> UserDefaults {
        let suite = "PreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private let italy = Region(code: "IT")
    private let covered = [Region.spain, Region(code: "IT"), Region.unitedStates]

    @Test func unsupportedRegionFallsBackToUSAndIsSaved() {
        let defaults = makeDefaults()
        let prefs = Preferences(defaultRegion: Region(code: "KP"), defaults: defaults)

        prefs.adoptSupportedRegion(among: covered)

        #expect(prefs.region == .unitedStates)
        #expect(Preferences(defaultRegion: italy, defaults: defaults).region == .unitedStates)
    }

    /// A covered device default isn't saved, so it keeps following the device.
    @Test func supportedDefaultIsKeptAndNotSaved() {
        let defaults = makeDefaults()
        let prefs = Preferences(defaultRegion: italy, defaults: defaults)

        prefs.adoptSupportedRegion(among: covered)

        #expect(prefs.region == italy)
        #expect(defaults.string(forKey: "settings.region.code") == nil)
    }

    @Test func spanishContentFollowsTheHomeRegion() {
        let prefs = Preferences(defaultRegion: .spain, defaultLanguage: .spanishES, defaults: makeDefaults())
        #expect(prefs.contentLanguage == .spanishES)

        prefs.region = Region(code: "MX")
        #expect(prefs.contentLanguage == .spanishMX)
        // The interface keeps its one Spanish.
        #expect(prefs.language == .spanishES)
    }
}
