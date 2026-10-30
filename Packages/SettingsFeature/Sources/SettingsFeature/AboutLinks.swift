//
//  AboutLinks.swift
//  SettingsFeature
//
//  Where Settings → About's links go. TMDB's terms ask for the attribution
//  link; App Store guideline 5.1.1(i) for the privacy policy in the app.
//

import Foundation

enum AboutLinks {
    static let tmdb = URL(string: "https://www.themoviedb.org")!
    static let justWatch = URL(string: "https://www.justwatch.com")!

    /// The policy page in the interface's language: Spanish has its own,
    /// everything else gets the English one.
    static func privacyPolicy(for locale: Locale = .current) -> URL {
        locale.language.languageCode == .spanish
            ? URL(string: "https://martingarcialopez.github.io/StreamIn/es/privacy/")!
            : URL(string: "https://martingarcialopez.github.io/StreamIn/privacy/")!
    }
}
