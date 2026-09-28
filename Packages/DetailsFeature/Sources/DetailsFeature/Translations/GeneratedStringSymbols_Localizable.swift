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
     VoiceOver label for the region flag strip on a Details provider row. %1$@ is the provider name, %2$lld is the count of regions.
     
     Localized string for key “detailsRegionStripAccessibility” in table “Localizable.xcstrings”.
     */
    static func detailsRegionStripAccessibility(_ arg1: String, _ arg2: Int) -> LocalizedStringResource {
        LocalizedStringResource("detailsRegionStripAccessibility", defaultValue: "\(arg1)\(arg2, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Done button that dismisses the full region list sheet
     
     Localized string for key “detailsRegionsSheetDone” in table “Localizable.xcstrings”.
     */
    static var detailsRegionsSheetDone: LocalizedStringResource {
        LocalizedStringResource("detailsRegionsSheetDone", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Button on the Details screen that re-runs the failed full-details load
     
     Localized string for key “detailsRetry” in table “Localizable.xcstrings”.
     */
    static var detailsRetry: LocalizedStringResource {
        LocalizedStringResource("detailsRetry", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Caption next to a list of regions where a given provider carries the film
     
     Localized string for key “detailsSubscriptionsAvailableIn” in table “Localizable.xcstrings”.
     */
    static var detailsSubscriptionsAvailableIn: LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsAvailableIn", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Button in the no-subscriptions state that opens the streaming-services picker
     
     Localized string for key “detailsSubscriptionsConfigureButton” in table “Localizable.xcstrings”.
     */
    static var detailsSubscriptionsConfigureButton: LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsConfigureButton", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Empty state shown when the user has not configured any subscriptions
     
     Localized string for key “detailsSubscriptionsEmptyConfigure” in table “Localizable.xcstrings”.
     */
    static var detailsSubscriptionsEmptyConfigure: LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsEmptyConfigure", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when none of the user's subscriptions carry the film in their home region. %@ is the 'flag + name' label for the home region.
     
     Localized string for key “detailsSubscriptionsHomeNotAvailable” in table “Localizable.xcstrings”.
     */
    static func detailsSubscriptionsHomeNotAvailable(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsHomeNotAvailable", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header above providers carrying the film in the user's home region. %@ is a 'flag + name' label, e.g. '🇪🇸 Spain'.
     
     Localized string for key “detailsSubscriptionsHomeRegion” in table “Localizable.xcstrings”.
     */
    static func detailsSubscriptionsHomeRegion(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsHomeRegion", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Empty state shown when the film isn't available with any of the user's subscriptions in any region
     
     Localized string for key “detailsSubscriptionsNoMatches” in table “Localizable.xcstrings”.
     */
    static var detailsSubscriptionsNoMatches: LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsNoMatches", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header above the per-provider flag strips for regions other than home (accessible via VPN)
     
     Localized string for key “detailsSubscriptionsOtherRegions” in table “Localizable.xcstrings”.
     */
    static var detailsSubscriptionsOtherRegions: LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsOtherRegions", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header for the multi-region availability across the user's subscriptions
     
     Localized string for key “detailsSubscriptionsSectionTitle” in table “Localizable.xcstrings”.
     */
    static var detailsSubscriptionsSectionTitle: LocalizedStringResource {
        LocalizedStringResource("detailsSubscriptionsSectionTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header on the Details screen above the streaming providers
     
     Localized string for key “detailsWhereToWatch” in table “Localizable.xcstrings”.
     */
    static var detailsWhereToWatch: LocalizedStringResource {
        LocalizedStringResource("detailsWhereToWatch", table: "Localizable", bundle: resourceBundleDescription)
    }
}