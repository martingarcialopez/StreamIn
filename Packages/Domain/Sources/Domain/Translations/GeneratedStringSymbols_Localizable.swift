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
     Shown when a request is cancelled mid-flight
     
     Localized string for key “errorCancelled” in table “Localizable.xcstrings”.
     */
    static var errorCancelled: LocalizedStringResource {
        LocalizedStringResource("errorCancelled", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when the API response cannot be parsed (schema drift)
     
     Localized string for key “errorDecoding” in table “Localizable.xcstrings”.
     */
    static var errorDecoding: LocalizedStringResource {
        LocalizedStringResource("errorDecoding", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when a requested movie or resource does not exist
     
     Localized string for key “errorNotFound” in table “Localizable.xcstrings”.
     */
    static var errorNotFound: LocalizedStringResource {
        LocalizedStringResource("errorNotFound", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when the device has no network connection
     
     Localized string for key “errorOffline” in table “Localizable.xcstrings”.
     */
    static var errorOffline: LocalizedStringResource {
        LocalizedStringResource("errorOffline", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when the TMDB API rate-limits the client
     
     Localized string for key “errorRateLimited” in table “Localizable.xcstrings”.
     */
    static var errorRateLimited: LocalizedStringResource {
        LocalizedStringResource("errorRateLimited", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown for HTTP 5xx server errors
     
     Localized string for key “errorServer” in table “Localizable.xcstrings”.
     */
    static var errorServer: LocalizedStringResource {
        LocalizedStringResource("errorServer", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when a network request exceeds its timeout
     
     Localized string for key “errorTimeout” in table “Localizable.xcstrings”.
     */
    static var errorTimeout: LocalizedStringResource {
        LocalizedStringResource("errorTimeout", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Shown when the TMDB API key is invalid or missing
     
     Localized string for key “errorUnauthorized” in table “Localizable.xcstrings”.
     */
    static var errorUnauthorized: LocalizedStringResource {
        LocalizedStringResource("errorUnauthorized", table: "Localizable", bundle: resourceBundleDescription)
    }

    /**
     Generic fallback error message
     
     Localized string for key “errorUnknown” in table “Localizable.xcstrings”.
     */
    static var errorUnknown: LocalizedStringResource {
        LocalizedStringResource("errorUnknown", table: "Localizable", bundle: resourceBundleDescription)
    }
}