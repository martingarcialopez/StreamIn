// MARK: - Provider catalog DTOs
//
// `/watch/providers/movie` returns the list of every streaming service TMDB
// knows about (optionally filtered by `watch_region`). The shape includes a
// `display_priorities` dictionary per provider for region-specific ordering;
// we don't need that yet, but it's left here as a TODO marker so we can sort
// per-region without a wire-format change.

public struct TMDBProviderListResponse: Decodable, Sendable {
    public let results: [TMDBProviderListItemDTO]
}
