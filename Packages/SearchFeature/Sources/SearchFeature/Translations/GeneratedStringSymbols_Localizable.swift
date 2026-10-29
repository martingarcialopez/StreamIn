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
     Search result row, in place of provider logos: something streams the movie in the user's region, but none of the user's services
     
     Localized string for key “searchRowNotOnYourServices” in table “Localizable.xcstrings”.
     */
    static var searchRowNotOnYourServices: LocalizedStringResource {
        LocalizedStringResource("searchRowNotOnYourServices", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Search result row, in place of provider logos: no subscription or free service streams the movie in the user's region
     
     Localized string for key “searchRowNotStreamingHere” in table “Localizable.xcstrings”.
     */
    static var searchRowNotStreamingHere: LocalizedStringResource {
        LocalizedStringResource("searchRowNotStreamingHere", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, search result row: the user's services or free ones that stream the movie at home. %@ is a list of service names
     
     Localized string for key “searchRowOnProviders” in table “Localizable.xcstrings”.
     */
    static func searchRowOnProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("searchRowOnProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Navigation bar title for the Search screen; "StreamIn" is the app brand name
     
     Localized string for key “searchTitle” in table “Localizable.xcstrings”.
     */
    static var searchTitle: LocalizedStringResource {
        LocalizedStringResource("searchTitle", table: "Localizable", bundle: resourceBundleDescription)
    }
}