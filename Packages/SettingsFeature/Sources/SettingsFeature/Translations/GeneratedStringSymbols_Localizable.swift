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
     Onboarding: one quiet credit line at the end of the services list. Same copy as the landing page's credits.
     
     Localized string for key “onboardingCredits” in table “Localizable.xcstrings”.
     */
    static var onboardingCredits: LocalizedStringResource {
        LocalizedStringResource("onboardingCredits", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Toolbar button that dismisses the onboarding sheet
     
     Localized string for key “onboardingDone” in table “Localizable.xcstrings”.
     */
    static var onboardingDone: LocalizedStringResource {
        LocalizedStringResource("onboardingDone", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Onboarding: one line under the headline saying what picking services gets you.
     
     Localized string for key “onboardingHeaderSubtitle” in table “Localizable.xcstrings”.
     */
    static var onboardingHeaderSubtitle: LocalizedStringResource {
        LocalizedStringResource("onboardingHeaderSubtitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Onboarding: headline under the spinning globe, above the services picker.
     
     Localized string for key “onboardingHeaderTitle” in table “Localizable.xcstrings”.
     */
    static var onboardingHeaderTitle: LocalizedStringResource {
        LocalizedStringResource("onboardingHeaderTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Navigation bar title for the first-launch onboarding screen
     
     Localized string for key “onboardingNavTitle” in table “Localizable.xcstrings”.
     */
    static var onboardingNavTitle: LocalizedStringResource {
        LocalizedStringResource("onboardingNavTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings → About: credit for the watch-provider data; opens justwatch.com.
     
     Localized string for key “settingsAboutJustWatch” in table “Localizable.xcstrings”.
     */
    static var settingsAboutJustWatch: LocalizedStringResource {
        LocalizedStringResource("settingsAboutJustWatch", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings → About: link to StreamIn's privacy policy web page.
     
     Localized string for key “settingsAboutPrivacy” in table “Localizable.xcstrings”.
     */
    static var settingsAboutPrivacy: LocalizedStringResource {
        LocalizedStringResource("settingsAboutPrivacy", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings → About: TMDB's required attribution, under their logo; opens themoviedb.org. Wording set by TMDB's terms.
     
     Localized string for key “settingsAboutTMDB” in table “Localizable.xcstrings”.
     */
    static var settingsAboutTMDB: LocalizedStringResource {
        LocalizedStringResource("settingsAboutTMDB", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings → About: the app version, then the build number in parentheses, e.g. Version 1.0.0 (1).
     
     Localized string for key “settingsAboutVersion” in table “Localizable.xcstrings”.
     */
    static func settingsAboutVersion(_ arg1: String, _ arg2: String) -> LocalizedStringResource {
        LocalizedStringResource("settingsAboutVersion", defaultValue: "\(arg1)\(arg2)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Toolbar button that dismisses the Settings sheet
     
     Localized string for key “settingsDone” in table “Localizable.xcstrings”.
     */
    static var settingsDone: LocalizedStringResource {
        LocalizedStringResource("settingsDone", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings: footer under the Language picker, before the restart note.
     
     Localized string for key “settingsLanguageFooter” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageFooter: LocalizedStringResource {
        LocalizedStringResource("settingsLanguageFooter", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Label for the language picker control
     
     Localized string for key “settingsLanguagePicker” in table “Localizable.xcstrings”.
     */
    static var settingsLanguagePicker: LocalizedStringResource {
        LocalizedStringResource("settingsLanguagePicker", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Cancel button on the restart alert; defers the relaunch to the user's next manual app open
     
     Localized string for key “settingsLanguageRestartLater” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageRestartLater: LocalizedStringResource {
        LocalizedStringResource("settingsLanguageRestartLater", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Body of the restart alert, explaining that the change is saved even if the user defers the restart
     
     Localized string for key “settingsLanguageRestartMessage” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageRestartMessage: LocalizedStringResource {
        LocalizedStringResource("settingsLanguageRestartMessage", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings: second footer line under the Language picker, with a restart icon; says a new language applies only after StreamIn restarts.
     
     Localized string for key “settingsLanguageRestartNote” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageRestartNote: LocalizedStringResource {
        LocalizedStringResource("settingsLanguageRestartNote", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Primary button on the restart alert, quits the app so the user can reopen it
     
     Localized string for key “settingsLanguageRestartNow” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageRestartNow: LocalizedStringResource {
        LocalizedStringResource("settingsLanguageRestartNow", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Title of the alert shown after the user changes the app language
     
     Localized string for key “settingsLanguageRestartTitle” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageRestartTitle: LocalizedStringResource {
        LocalizedStringResource("settingsLanguageRestartTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Services picker: placeholder of the search field that filters services by name.
     
     Localized string for key “settingsMoreProvidersSearchPrompt” in table “Localizable.xcstrings”.
     */
    static var settingsMoreProvidersSearchPrompt: LocalizedStringResource {
        LocalizedStringResource("settingsMoreProvidersSearchPrompt", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Services picker: switch under the 'Available in …' heading that lists every service in the world instead of the home region's.
     
     Localized string for key “settingsMoreProvidersWorldwideToggle” in table “Localizable.xcstrings”.
     */
    static var settingsMoreProvidersWorldwideToggle: LocalizedStringResource {
        LocalizedStringResource("settingsMoreProvidersWorldwideToggle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Settings: footer under the Region picker.
     
     Localized string for key “settingsRegionFooter” in table “Localizable.xcstrings”.
     */
    static var settingsRegionFooter: LocalizedStringResource {
        LocalizedStringResource("settingsRegionFooter", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Label for the region picker control
     
     Localized string for key “settingsRegionPicker” in table “Localizable.xcstrings”.
     */
    static var settingsRegionPicker: LocalizedStringResource {
        LocalizedStringResource("settingsRegionPicker", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Services picker: button that asks again for the list of services after a failure.
     
     Localized string for key “settingsRetry” in table “Localizable.xcstrings”.
     */
    static var settingsRetry: LocalizedStringResource {
        LocalizedStringResource("settingsRetry", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Services picker: shown under 'Available in …' when every service there is already one of yours.
     
     Localized string for key “settingsStreamingServicesAllPicked” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesAllPicked: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesAllPicked", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header on the picker screen above providers available in the user's home region. %@ is the localized region name.
     
     Localized string for key “settingsStreamingServicesAvailableInRegion” in table “Localizable.xcstrings”.
     */
    static func settingsStreamingServicesAvailableInRegion(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesAvailableInRegion", defaultValue: "\(arg1)", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header on the picker screen when the worldwide toggle is on
     
     Localized string for key “settingsStreamingServicesAvailableWorldwide” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesAvailableWorldwide: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesAvailableWorldwide", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Trailing summary on the Settings row showing how many streaming services the user has selected. %lld is the count.
     
     Localized string for key “settingsStreamingServicesCount” in table “Localizable.xcstrings”.
     */
    static func settingsStreamingServicesCount(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesCount", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Services picker: title shown in place of the grid when the list of services couldn't be loaded; the reason and a Retry button follow.
     
     Localized string for key “settingsStreamingServicesLoadFailed” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesLoadFailed: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesLoadFailed", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Trailing summary on the Settings row when the user hasn't selected any streaming services
     
     Localized string for key “settingsStreamingServicesNone” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesNone: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesNone", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Label for the navigation row in Settings that opens the streaming services picker
     
     Localized string for key “settingsStreamingServicesRow” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesRow: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesRow", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Navigation title of the pushed streaming services picker screen
     
     Localized string for key “settingsStreamingServicesTitle” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesTitle: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesTitle", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Footer explaining when to enable the worldwide toggle on the picker screen
     
     Localized string for key “settingsStreamingServicesWorldwideFooter” in table “Localizable.xcstrings”.
     */
    static var settingsStreamingServicesWorldwideFooter: LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesWorldwideFooter", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Services picker: heading above the services you picked, with how many, e.g. Your services · 3.
     
     Localized string for key “settingsStreamingServicesYourServices” in table “Localizable.xcstrings”.
     */
    static func settingsStreamingServicesYourServices(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("settingsStreamingServicesYourServices", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Body text introducing the subscriptions section
     
     Localized string for key “settingsSubscriptionsBlurb” in table “Localizable.xcstrings”.
     */
    static var settingsSubscriptionsBlurb: LocalizedStringResource {
        LocalizedStringResource("settingsSubscriptionsBlurb", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Section header for the user's streaming subscription preferences
     
     Localized string for key “settingsSubscriptionsHeader” in table “Localizable.xcstrings”.
     */
    static var settingsSubscriptionsHeader: LocalizedStringResource {
        LocalizedStringResource("settingsSubscriptionsHeader", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Navigation bar title for the Settings sheet
     
     Localized string for key “settingsTitle” in table “Localizable.xcstrings”.
     */
    static var settingsTitle: LocalizedStringResource {
        LocalizedStringResource("settingsTitle", table: "Localizable", bundle: resourceBundleDescription)
    }
}