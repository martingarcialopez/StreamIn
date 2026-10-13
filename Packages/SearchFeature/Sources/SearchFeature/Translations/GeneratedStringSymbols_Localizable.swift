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
     Shown in a search result row when the movie has no streaming subscriptions in the user's region
     
     Localized string for key “searchNoStreamingInRegion” in table “Localizable.xcstrings”.
     */
    static var searchNoStreamingInRegion: LocalizedStringResource {
        LocalizedStringResource("searchNoStreamingInRegion", table: "Localizable", bundle: resourceBundleDescription)
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
     Navigation bar title for the Search screen; "StreamIn" is the app brand name
     
     Localized string for key “searchTitle” in table “Localizable.xcstrings”.
     */
    static var searchTitle: LocalizedStringResource {
        LocalizedStringResource("searchTitle", table: "Localizable", bundle: resourceBundleDescription)
    }
}