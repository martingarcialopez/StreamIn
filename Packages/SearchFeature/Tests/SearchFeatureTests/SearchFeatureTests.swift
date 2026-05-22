import Testing
@testable import SearchFeature

@Suite("SearchResultsRoute")
struct SearchResultsRouteTests {

    @Test func storesQueryVerbatim() {
        let route = SearchResultsRoute(query: "Blade Runner")
        #expect(route.query == "Blade Runner")
    }

    @Test func equalForSameQuery() {
        #expect(SearchResultsRoute(query: "Inception") == SearchResultsRoute(query: "Inception"))
    }

    @Test func notEqualForDifferentQuery() {
        #expect(SearchResultsRoute(query: "Inception") != SearchResultsRoute(query: "Dune"))
    }

    @Test func hashableContractMatchesEquality() {
        let a = SearchResultsRoute(query: "Inception")
        let b = SearchResultsRoute(query: "Inception")
        var seen: Set<SearchResultsRoute> = []
        seen.insert(a)
        seen.insert(b)
        // Same query → same hash → set dedupes to one entry.
        #expect(seen.count == 1)
    }

    @Test func queryIsCaseSensitive() {
        // Deliberate: TMDB search treats casing differently across regions and
        // we'd rather not collapse "her" / "Her" into one route. If the product
        // ever wants case-insensitive routing, do it at the boundary, not here.
        #expect(SearchResultsRoute(query: "her") != SearchResultsRoute(query: "Her"))
    }
}

@Suite("SearchView.sanitize")
struct SearchViewSanitizeTests {

    @Test func trimsLeadingAndTrailingWhitespace() {
        #expect(SearchView.sanitize("  inception  ") == "inception")
    }

    @Test func preservesInternalWhitespace() {
        #expect(SearchView.sanitize(" blade  runner ") == "blade  runner")
    }

    @Test func rejectsEmptyString() {
        #expect(SearchView.sanitize("") == nil)
    }

    @Test func rejectsWhitespaceOnly() {
        #expect(SearchView.sanitize("   ") == nil)
        #expect(SearchView.sanitize("\n\t  ") == nil)
    }

    @Test func passesThroughCleanInput() {
        #expect(SearchView.sanitize("inception") == "inception")
    }
}
