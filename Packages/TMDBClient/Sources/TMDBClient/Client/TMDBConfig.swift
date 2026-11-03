//  TMDBConfig.swift
//  StreamIn
//
//  Data layer — knows about HTTP, JSON, TMDB's API shape, and how to translate
//  those things into the Domain layer's vocabulary. Nothing upstream of this
//  module sees a `TMDBMovieDTO` or constructs a URL.

import Foundation

// MARK: - Configuration

public struct TMDBConfig: Sendable {
    public let baseURL: URL
    public let apiKey: String
    /// Default language sent as `language=` (e.g. "en-US", "es-ES"), after
    /// `contentLanguage(for:)`.
    public let language: String

    public init(
        baseURL: URL = URL(string: "https://api.themoviedb.org/3")!,
        apiKey: String,
        language: String = "en-US"
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.language = Self.contentLanguage(for: language)
    }

    /// The `language=` TMDB gets for the app's language. Any English asks for
    /// en-US: few movies have an en-GB translation, and one without it comes
    /// back with an empty overview. The app's English is British all the same.
    public static func contentLanguage(for code: String) -> String {
        code.hasPrefix("en-") ? "en-US" : code
    }
}
