// 
// GeneratedStringSymbols_Localizable.swift
// Auto-Generated symbols for localized strings defined in “Localizable.xcstrings”.
// 

import Foundation

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
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