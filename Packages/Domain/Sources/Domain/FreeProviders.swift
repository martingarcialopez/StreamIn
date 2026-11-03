//
//  FreeProviders.swift
//  Domain
//
//  Services that cost nothing (public broadcasters' players, ad-supported
//  streamers). TMDB's provider list doesn't say which are free, so they are
//  curated here, like `ProviderAliases`. The services picker is for services
//  you pay for, so it leaves them out; a movie's availability still shows
//  them when they stream it.
//
//  Matching is by id or by name (case and diacritics ignored), because ids
//  differ per region for the same broadcaster. Add a group when one surfaces.
//

import Foundation

public enum FreeProviders {

    private static let ids: Set<ProviderID> = [
        ProviderID(300),   // Pluto TV
        ProviderID(1965),  // Pluto TV Live
        ProviderID(73),    // Tubi TV
        ProviderID(538),   // Plex
        ProviderID(207),   // The Roku Channel
        ProviderID(12),    // Crackle
        ProviderID(38),    // BBC iPlayer
        ProviderID(41),    // ITVX
        ProviderID(103),   // Channel 4
        ProviderID(333)    // My5
    ]

    private static let names: Set<String> = [
        "rtve play", "rtve", "atresplayer", "mitele", "pluto tv", "tubi tv",
        "plex", "the roku channel", "bbc iplayer", "itvx", "channel 4",
        "my5", "arte", "zdf", "ard mediathek", "rai play", "france tv",
        "play suisse", "svt play", "nrk tv", "yle areena"
    ]

    /// Whether `provider` is a free service, not one you subscribe to.
    public static func contains(_ provider: WatchProvider) -> Bool {
        ids.contains(provider.id)
            || names.contains(provider.name.lowercased().folding(options: .diacriticInsensitive, locale: nil))
    }
}
