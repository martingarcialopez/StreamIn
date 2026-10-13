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
     VoiceOver label for the small logos on the Details card's top border, when the user can already watch the film: the region's other services. Followed by their names.
     
     Localized string for key “detailsAlsoOn” in table “Localizable.xcstrings”.
     */
    static var detailsAlsoOn: LocalizedStringResource {
        LocalizedStringResource("detailsAlsoOn", table: "Localizable", bundle: resourceBundleDescription)
    }

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
     VoiceOver label for the small logos on the Details card's top border: services the user doesn't have that carry the film in their region. %@ is the region name, e.g. 'Spain'. Followed by their names.
     
     Localized string for key “detailsInRegion” in table “Localizable.xcstrings”.
     */
    static func detailsInRegion(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsInRegion", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Error message on the Details screen when full details fail to load; %@ is the localized underlying error description
     
     Localized string for key “detailsLoadFailed” in table “Localizable.xcstrings”.
     */
    static func detailsLoadFailed(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsLoadFailed", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
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
     Line under 'Go read a book' when services the user doesn't have carry the film in their region
     
     Localized string for key “detailsUnavailableNotOnYours” in table “Localizable.xcstrings”.
     */
    static var detailsUnavailableNotOnYours: LocalizedStringResource {
        LocalizedStringResource("detailsUnavailableNotOnYours", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Line under 'Go read a book' when no service carries the film in the user's region and none of theirs carries it abroad. 'Here' is the region the card's title shows with its flag.
     
     Localized string for key “detailsUnavailableNowhere” in table “Localizable.xcstrings”.
     */
    static var detailsUnavailableNowhere: LocalizedStringResource {
        LocalizedStringResource("detailsUnavailableNowhere", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Verdict on the Details card when the film is only on the user's services in other countries
     
     Localized string for key “detailsVerdictAbroad” in table “Localizable.xcstrings”.
     */
    static var detailsVerdictAbroad: LocalizedStringResource {
        LocalizedStringResource("detailsVerdictAbroad", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Playful verdict on the Details card when the user can't stream the film: not on their services anywhere and not free in their region
     
     Localized string for key “detailsVerdictUnavailable” in table “Localizable.xcstrings”.
     */
    static var detailsVerdictUnavailable: LocalizedStringResource {
        LocalizedStringResource("detailsVerdictUnavailable", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Verdict on the Details card when one of the user's services, or a free service, carries the film in their region
     
     Localized string for key “detailsVerdictWatchNow” in table “Localizable.xcstrings”.
     */
    static var detailsVerdictWatchNow: LocalizedStringResource {
        LocalizedStringResource("detailsVerdictWatchNow", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     VoiceOver label of the Details 'where to watch' card title, whose visible text shows only the region's flag. %@ is the region name, e.g. 'Spain'.
     
     Localized string for key “detailsWhereToWatchRegion” in table “Localizable.xcstrings”.
     */
    static func detailsWhereToWatchRegion(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsWhereToWatchRegion", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Small title of the Details 'where to watch' card. %@ is the home region's flag emoji, e.g. '🇪🇸'.
     
     Localized string for key “detailsWhereToWatchTitle” in table “Localizable.xcstrings”.
     */
    static func detailsWhereToWatchTitle(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("detailsWhereToWatchTitle", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }
}