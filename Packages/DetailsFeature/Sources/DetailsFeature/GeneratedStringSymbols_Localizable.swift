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
     Shown on the Details screen while the providers list is loading
     
     Localized string for key “detailsCheckingAvailability” in table “Localizable.xcstrings”.
     */
    static var detailsCheckingAvailability: LocalizedStringResource {
        LocalizedStringResource("detailsCheckingAvailability", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Director credit on the Details screen; %@ is a locale-formatted list of director names
     
     Localized string for key “detailsDirectedBy” in table “Localizable.xcstrings”.
     */
    static func detailsDirectedBy(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsDirectedBy", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Error message on the Details screen when full details fail to load; %@ is the localized underlying error description
     
     Localized string for key “detailsLoadFailed” in table “Localizable.xcstrings”.
     */
    static func detailsLoadFailed(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsLoadFailed", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown on the Details screen when no streaming providers cover the user's region
     
     Localized string for key “detailsNotAvailable” in table “Localizable.xcstrings”.
     */
    static var detailsNotAvailable: LocalizedStringResource {
        LocalizedStringResource("detailsNotAvailable", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Sub-section header for movies available to watch for free
     
     Localized string for key “detailsProvidersFree” in table “Localizable.xcstrings”.
     */
    static var detailsProvidersFree: LocalizedStringResource {
        LocalizedStringResource("detailsProvidersFree", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Sub-section header for movies available via a streaming subscription
     
     Localized string for key “detailsProvidersSubscription” in table “Localizable.xcstrings”.
     */
    static var detailsProvidersSubscription: LocalizedStringResource {
        LocalizedStringResource("detailsProvidersSubscription", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Button on the Details screen that re-runs the failed full-details load
     
     Localized string for key “detailsRetry” in table “Localizable.xcstrings”.
     */
    static var detailsRetry: LocalizedStringResource {
        LocalizedStringResource("detailsRetry", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header on the Details screen above the streaming providers
     
     Localized string for key “detailsWhereToWatch” in table “Localizable.xcstrings”.
     */
    static var detailsWhereToWatch: LocalizedStringResource {
        LocalizedStringResource("detailsWhereToWatch", table: "Localizable", bundle: resourceBundleDescription)
    }
}