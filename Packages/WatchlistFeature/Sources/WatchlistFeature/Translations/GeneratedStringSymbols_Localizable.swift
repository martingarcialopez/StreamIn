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
     Directors line under a movie title in a Watchlist row when the movie has three or more directors: the first two names, then how many more. %1$@ and %2$@ are director names, %3$lld is the number of remaining directors.
     
     Localized string for key “watchlistDirectorsOverflow” in table “Localizable.xcstrings”.
     */
    static func watchlistDirectorsOverflow(_ arg1: String, _ arg2: String, _ arg3: Int) -> LocalizedStringResource {
        LocalizedStringResource("watchlistDirectorsOverflow", defaultValue: "\(arg1)\(arg2)\(arg3, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Hint under the headline on the empty Watchlist screen: how to save movies with the heart button on a movie's page, and what the list then shows
     
     Localized string for key “watchlistEmptyDescription” in table “Localizable.xcstrings”.
     */
    static var watchlistEmptyDescription: LocalizedStringResource {
        LocalizedStringResource("watchlistEmptyDescription", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Headline on the Watchlist screen when no movies have been saved
     
     Localized string for key “watchlistEmptyTitle” in table “Localizable.xcstrings”.
     */
    static var watchlistEmptyTitle: LocalizedStringResource {
        LocalizedStringResource("watchlistEmptyTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Description under the title when the Watchlist couldn't be loaded; reassures that nothing was lost
     
     Localized string for key “watchlistLoadFailedDescription” in table “Localizable.xcstrings”.
     */
    static var watchlistLoadFailedDescription: LocalizedStringResource {
        LocalizedStringResource("watchlistLoadFailedDescription", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Title on the Watchlist screen when the saved movies couldn't be read from the device
     
     Localized string for key “watchlistLoadFailedTitle” in table “Localizable.xcstrings”.
     */
    static var watchlistLoadFailedTitle: LocalizedStringResource {
        LocalizedStringResource("watchlistLoadFailedTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Button that tries loading the Watchlist again after it failed
     
     Localized string for key “watchlistRetry” in table “Localizable.xcstrings”.
     */
    static var watchlistRetry: LocalizedStringResource {
        LocalizedStringResource("watchlistRetry", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, Watchlist row: the user's services that stream the movie only in other regions. %@ is a list of service names
     
     Localized string for key “watchlistRowAbroadProviders” in table “Localizable.xcstrings”.
     */
    static func watchlistRowAbroadProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("watchlistRowAbroadProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Watchlist row, in place of provider logos: loading where to watch the movie failed (pull to refresh retries)
     
     Localized string for key “watchlistRowAvailabilityFailed” in table “Localizable.xcstrings”.
     */
    static var watchlistRowAvailabilityFailed: LocalizedStringResource {
        LocalizedStringResource("watchlistRowAvailabilityFailed", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, Watchlist row: where to watch the movie is still loading
     
     Localized string for key “watchlistRowCheckingAvailability” in table “Localizable.xcstrings”.
     */
    static var watchlistRowCheckingAvailability: LocalizedStringResource {
        LocalizedStringResource("watchlistRowCheckingAvailability", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Watchlist row, in place of provider logos: no subscription or free service streams the movie in the user's region
     
     Localized string for key “watchlistRowNotStreamingHere” in table “Localizable.xcstrings”.
     */
    static var watchlistRowNotStreamingHere: LocalizedStringResource {
        LocalizedStringResource("watchlistRowNotStreamingHere", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Watchlist row: caption before dimmed logos of services that stream the movie in the user's region but aren't the user's
     
     Localized string for key “watchlistRowNotYours” in table “Localizable.xcstrings”.
     */
    static var watchlistRowNotYours: LocalizedStringResource {
        LocalizedStringResource("watchlistRowNotYours", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, Watchlist row: the user's services or free ones that stream the movie at home. %@ is a list of service names
     
     Localized string for key “watchlistRowOnProviders” in table “Localizable.xcstrings”.
     */
    static func watchlistRowOnProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("watchlistRowOnProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver, watchlist row: services that stream the movie in the user's region but aren't the user's. %@ is a list of service names
     
     Localized string for key “watchlistRowOthersProviders” in table “Localizable.xcstrings”.
     */
    static func watchlistRowOthersProviders(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("watchlistRowOthersProviders", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Navigation bar title for the Watchlist tab
     
     Localized string for key “watchlistTitle” in table “Localizable.xcstrings”.
     */
    static var watchlistTitle: LocalizedStringResource {
        LocalizedStringResource("watchlistTitle", table: "Localizable", bundle: resourceBundleDescription)
    }
}