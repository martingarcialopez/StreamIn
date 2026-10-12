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
     Description on the empty watchlist screen explaining how to add movies
     
     Localized string for key “watchlistEmptyDescription” in table “Localizable.xcstrings”.
     */
    static var watchlistEmptyDescription: LocalizedStringResource {
        LocalizedStringResource("watchlistEmptyDescription", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Title shown on the watchlist screen when no movies have been saved
     
     Localized string for key “watchlistEmptyTitle” in table “Localizable.xcstrings”.
     */
    static var watchlistEmptyTitle: LocalizedStringResource {
        LocalizedStringResource("watchlistEmptyTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Navigation bar title for the Watchlist tab
     
     Localized string for key “watchlistTitle” in table “Localizable.xcstrings”.
     */
    static var watchlistTitle: LocalizedStringResource {
        LocalizedStringResource("watchlistTitle", table: "Localizable", bundle: resourceBundleDescription)
    }
}