import Testing
import Foundation
@testable import Domain

// MARK: - ProviderAliases

/// Pins each curated alias group to its canonical id. If a future edit
/// accidentally drops an id from a group or moves it to the wrong group,
/// these tests fail with a concrete diff against the documented intent.
@Suite struct ProviderAliasesTests {

    @Test func netflixVariantsCanonicalizeTo8() {
        for id in [8, 175, 1796] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(8),
                    "Netflix variant \(id) should canonicalize to 8")
        }
    }

    @Test func primeVideoVariantsCanonicalizeTo9() {
        for id in [9, 119, 613, 2100] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(9),
                    "Prime Video variant \(id) should canonicalize to 9")
        }
    }

    @Test func disneyVariantsCanonicalizeTo122() {
        for id in [122, 337] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(122),
                    "Disney+ variant \(id) should canonicalize to 122")
        }
    }

    @Test func paramountTiersCanonicalizeTo531() {
        for id in [531, 2303, 2304, 2616] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(531),
                    "Paramount+ tier \(id) should canonicalize to 531")
        }
    }

    @Test func peacockTiersCanonicalizeTo386() {
        for id in [386, 387] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(386))
        }
    }

    @Test func discoveryDuplicatesCanonicalizeTo510() {
        for id in [510, 520, 524] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(510))
        }
    }

    @Test func plutoTVVariantsCanonicalizeTo300() {
        for id in [300, 1965] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(300))
        }
    }

    @Test func starzRegionalRebrandsCanonicalizeTo43() {
        for id in [43, 561, 630] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(43))
        }
    }

    @Test func canalPlusCaseVariantsCanonicalizeTo381() {
        for id in [381, 2101] {
            #expect(ProviderAliases.canonical(ProviderID(id)) == ProviderID(381))
        }
    }

    /// Sanity-check that deliberately-separate ids stay separate. These are
    /// the "looks like an alias but isn't" cases from the survey output that
    /// would be tempting to merge if someone re-runs the discovery script
    /// without reading the comments.
    @Test func deliberatelySeparateIDsArentAliased() {
        // Apple TV+ subscription (350) and Apple TV Store (2) are different.
        #expect(ProviderAliases.canonical(ProviderID(2)) == ProviderID(2))
        #expect(ProviderAliases.canonical(ProviderID(350)) == ProviderID(350))

        // AMC linear channel (80) and AMC+ streaming sub (526) are different.
        #expect(ProviderAliases.canonical(ProviderID(80)) == ProviderID(80))
        #expect(ProviderAliases.canonical(ProviderID(526)) == ProviderID(526))

        // ESPN linear (1718) and ESPN+ streaming (1768) are different.
        #expect(ProviderAliases.canonical(ProviderID(1718)) == ProviderID(1718))
        #expect(ProviderAliases.canonical(ProviderID(1768)) == ProviderID(1768))

        // DisneyNOW (508) is the TV-Everywhere app, NOT Disney+ (122/337).
        #expect(ProviderAliases.canonical(ProviderID(508)) == ProviderID(508))

        // Amazon Video rent/buy storefront (10) is NOT Prime Video sub.
        #expect(ProviderAliases.canonical(ProviderID(10)) == ProviderID(10))

        // Channel add-ons (paid separately) — pick a few representative ones.
        // MUBI Amazon Channel (201) is NOT MUBI (11).
        #expect(ProviderAliases.canonical(ProviderID(201)) == ProviderID(201))
        #expect(ProviderAliases.canonical(ProviderID(11)) == ProviderID(11))
        // Paramount+ Amazon Channel (582) is NOT Paramount+ (531).
        #expect(ProviderAliases.canonical(ProviderID(582)) == ProviderID(582))
        // Crunchyroll Amazon Channel (1968) is NOT Crunchyroll (283).
        #expect(ProviderAliases.canonical(ProviderID(1968)) == ProviderID(1968))
        #expect(ProviderAliases.canonical(ProviderID(283)) == ProviderID(283))
    }

    @Test func unaliasedIDPassesThrough() {
        // Random id that's not in any group — should return itself.
        #expect(ProviderAliases.canonical(ProviderID(999_999)) == ProviderID(999_999))
    }

    @Test func aliasGroupExpandsForCanonicalAndVariants() {
        let primeGroup = ProviderAliases.aliasGroup(of: ProviderID(9))
        #expect(primeGroup == Set([ProviderID(9), ProviderID(119), ProviderID(613), ProviderID(2100)]))

        // Asking from any variant returns the same group.
        let fromVariant = ProviderAliases.aliasGroup(of: ProviderID(119))
        #expect(fromVariant == primeGroup)

        // Unaliased id returns a singleton.
        #expect(ProviderAliases.aliasGroup(of: ProviderID(283)) == Set([ProviderID(283)]))
    }
}

// MARK: - ProviderAliases.merging

@Suite struct ProviderMergingTests {

    private func provider(_ id: Int, _ name: String, priority: Int) -> WatchProvider {
        WatchProvider(id: ProviderID(id), name: name, logoPath: ImagePath("/\(id).png"), priority: priority)
    }

    /// TMDB lists Netflix and its ad tier side by side in one region; the
    /// app must show one Netflix.
    @Test func collapsesAliasesIntoOneEntryPerBrand() {
        let merged = ProviderAliases.merging([
            provider(8, "Netflix", priority: 3),
            provider(1796, "Netflix Standard with Ads", priority: 1),
            provider(337, "Disney Plus", priority: 5)
        ])

        #expect(merged.map(\.id) == [ProviderID(8), ProviderID(122)])
        let netflix = merged[0]
        #expect(netflix.name == "Netflix")
        #expect(netflix.logoPath == ImagePath("/8.png"))
        #expect(netflix.priority == 1)
    }

    @Test func canonicalMetadataWinsEvenWhenSeenLast() {
        let merged = ProviderAliases.merging([
            provider(2100, "Amazon Prime Video with Ads", priority: 4),
            provider(119, "Amazon Prime Video (LatAm)", priority: 2),
            provider(9, "Amazon Prime Video", priority: 6)
        ])

        #expect(merged == [
            WatchProvider(id: ProviderID(9), name: "Amazon Prime Video", logoPath: ImagePath("/9.png"), priority: 2)
        ])
    }

    @Test func firstSeenMetadataWithoutACanonicalEntry() {
        let merged = ProviderAliases.merging([
            provider(1796, "Netflix Standard with Ads", priority: 2),
            provider(175, "Netflix Kids", priority: 1)
        ])

        #expect(merged.map(\.id) == [ProviderID(8)])
        #expect(merged.first?.name == "Netflix Standard with Ads")
        #expect(merged.first?.priority == 1)
    }

    @Test func unaliasedProvidersKeepTheirOrder() {
        let input = [
            provider(283, "Crunchyroll", priority: 9),
            provider(8, "Netflix", priority: 1),
            provider(350, "Apple TV+", priority: 4)
        ]
        #expect(ProviderAliases.merging(input) == input)
    }
}

// MARK: - Language

@Suite struct LanguageTests {

    /// The picker switches the interface too, so it may only offer languages
    /// every String Catalog translates.
    @Test func pickerOffersOnlyTranslatedLanguages() {
        #expect(Language.allKnown.map(\.code) == ["en-US", "es-ES"])
    }

    @Test func exactMatchWins() {
        #expect(Language.currentLocale(for: Locale(identifier: "es_ES")) == .spanishES)
    }

    @Test func languageCodeMatchesAcrossRegions() {
        #expect(Language.currentLocale(for: Locale(identifier: "es_MX")) == .spanishES)
        #expect(Language.currentLocale(for: Locale(identifier: "en_GB")) == .englishUS)
    }

    /// An untranslated device language falls back to English, the language
    /// iOS shows the interface in, so content and interface agree.
    @Test func untranslatedLanguageFallsBackToEnglish() {
        #expect(Language.currentLocale(for: Locale(identifier: "fr_FR")) == .englishUS)
        #expect(Language.currentLocale(for: Locale(identifier: "it_IT")) == .englishUS)
    }
}

// MARK: - Region.flag

@Suite struct RegionFlagTests {

    @Test func twoLetterCodeYieldsTwoRegionalIndicatorScalars() {
        // The unicode scalars in the flag string should be the two regional
        // indicator symbols corresponding to the country code.
        let spain = Region(code: "ES")
        let scalars = Array(spain.flag.unicodeScalars)
        #expect(scalars.count == 2)
        // Regional indicator letter A is U+1F1E6 (127462). "E" is the 5th
        // letter (offset 4) → 127466; "S" is the 19th (offset 18) → 127480.
        #expect(scalars[0].value == 127_466)
        #expect(scalars[1].value == 127_480)
    }

    @Test func lowercaseInputIsUppercasedBeforeMapping() {
        // Region.init uppercases, so this should work transparently.
        let lowercase = Region(code: "es")
        let uppercase = Region(code: "ES")
        #expect(lowercase.flag == uppercase.flag)
    }

    @Test func flagsDifferAcrossCountries() {
        #expect(Region.spain.flag != Region.france.flag)
        #expect(Region.unitedStates.flag != Region.unitedKingdom.flag)
    }
}
