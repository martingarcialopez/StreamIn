// 
// GeneratedStringSymbols_Localizable.swift
// Auto-Generated symbols for localized strings defined in “Localizable.xcstrings”.
// 

import Foundation

#if SWIFT_PACKAGE
private nonisolated let resourceBundle = Foundation.Bundle.module
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.atURL(resourceBundle.bundleURL)
#else

private class ResourceBundleClass {}
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private nonisolated let resourceBundleDescription = LocalizedStringResource.BundleDescription.forClass(ResourceBundleClass.self)
#endif

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
nonisolated extension LocalizedStringResource {
    /**
     Description on the empty search screen instructing the user to type and press Return
     
     Localized string for key “searchEmptyState” in table “Localizable.xcstrings”.
     */
    static var searchEmptyState: LocalizedStringResource {
        LocalizedStringResource("searchEmptyState", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Title on the empty search screen prompting the user to start a search
     
     Localized string for key “searchEmptyTitle” in table “Localizable.xcstrings”.
     */
    static var searchEmptyTitle: LocalizedStringResource {
        LocalizedStringResource("searchEmptyTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown while a search query is in flight
     
     Localized string for key “searchInProgress” in table “Localizable.xcstrings”.
     */
    static var searchInProgress: LocalizedStringResource {
        LocalizedStringResource("searchInProgress", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Footer at the bottom of the search landing page crediting the data sources: TMDB (movie data) and JustWatch (where-to-watch data). Keep the brand names as they are.
     
     Localized string for key “searchLandingCredits” in table “Localizable.xcstrings”.
     */
    static var searchLandingCredits: LocalizedStringResource {
        LocalizedStringResource("searchLandingCredits", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver name for the landing page's movie reel when trending movies couldn't load and it shows film icons instead of posters
     
     Localized string for key “searchLandingSlotAnyMovie” in table “Localizable.xcstrings”.
     */
    static var searchLandingSlotAnyMovie: LocalizedStringResource {
        LocalizedStringResource("searchLandingSlotAnyMovie", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver name for the landing page's service reel when provider logos couldn't load and it shows TV icons instead
     
     Localized string for key “searchLandingSlotAnyService” in table “Localizable.xcstrings”.
     */
    static var searchLandingSlotAnyService: LocalizedStringResource {
        LocalizedStringResource("searchLandingSlotAnyService", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver hint of the landing page's slot machine: activating it spins the reels again
     
     Localized string for key “searchLandingSlotHint” in table “Localizable.xcstrings”.
     */
    static var searchLandingSlotHint: LocalizedStringResource {
        LocalizedStringResource("searchLandingSlotHint", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Voice Control name of the landing page's slot machine, the word users say to spin it (its spoken label changes with every spin)
     
     Localized string for key “searchLandingSlotInputLabel” in table “Localizable.xcstrings”.
     */
    static var searchLandingSlotInputLabel: LocalizedStringResource {
        LocalizedStringResource("searchLandingSlotInputLabel", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver label of the landing page's slot machine: the movie, streaming service and country its three reels stopped on. %1$@ movie title, %2$@ service name, %3$@ country name
     
     Localized string for key “searchLandingSlotLabel” in table “Localizable.xcstrings”.
     */
    static func searchLandingSlotLabel(_ arg1: String, _ arg2: String, _ arg3: String) -> LocalizedStringResource {
        LocalizedStringResource("searchLandingSlotLabel", defaultValue: "\(arg1)\(arg2)\(arg3)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Tagline under the app name on the search landing page, saying what the app does
     
     Localized string for key “searchLandingTagline” in table “Localizable.xcstrings”.
     */
    static var searchLandingTagline: LocalizedStringResource {
        LocalizedStringResource("searchLandingTagline", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Placeholder text inside the search field
     
     Localized string for key “searchPrompt” in table “Localizable.xcstrings”.
     */
    static var searchPrompt: LocalizedStringResource {
        LocalizedStringResource("searchPrompt", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Button that re-runs the failed search request
     
     Localized string for key “searchRetry” in table “Localizable.xcstrings”.
     */
    static var searchRetry: LocalizedStringResource {
        LocalizedStringResource("searchRetry", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, search result row: the user's services that stream the movie only in other regions. %@ is a list of service names
     
     Localized string for key “searchRowAbroadProviders” in table “Localizable.xcstrings”.
     */
    static func searchRowAbroadProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("searchRowAbroadProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Search result row, in place of provider logos: loading where to watch the movie failed (pull to refresh retries)
     
     Localized string for key “searchRowAvailabilityFailed” in table “Localizable.xcstrings”.
     */
    static var searchRowAvailabilityFailed: LocalizedStringResource {
        LocalizedStringResource("searchRowAvailabilityFailed", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, search result row: where to watch the movie is still loading
     
     Localized string for key “searchRowCheckingAvailability” in table “Localizable.xcstrings”.
     */
    static var searchRowCheckingAvailability: LocalizedStringResource {
        LocalizedStringResource("searchRowCheckingAvailability", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Search result row, in place of provider logos: no subscription or free service streams the movie in the user's region
     
     Localized string for key “searchRowNotStreamingHere” in table “Localizable.xcstrings”.
     */
    static var searchRowNotStreamingHere: LocalizedStringResource {
        LocalizedStringResource("searchRowNotStreamingHere", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Search result row: caption before dimmed logos of services that stream the movie in the user's region but aren't the user's
     
     Localized string for key “searchRowNotYours” in table “Localizable.xcstrings”.
     */
    static var searchRowNotYours: LocalizedStringResource {
        LocalizedStringResource("searchRowNotYours", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, search result row: the user's services or free ones that stream the movie at home. %@ is a list of service names
     
     Localized string for key “searchRowOnProviders” in table “Localizable.xcstrings”.
     */
    static func searchRowOnProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("searchRowOnProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, search result row: services that stream the movie in the user's region but aren't the user's. %@ is a list of service names
     
     Localized string for key “searchRowOthersProviders” in table “Localizable.xcstrings”.
     */
    static func searchRowOthersProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("searchRowOthersProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }
}