//
//  SearchView.swift
//  SearchFeature
//
//  Root view of the Search tab. Hosts `LandingView` — a centered logo + name
//  + custom search bar — and calls back to the App-level NavigationStack when
//  the user submits a query so it can push `SearchResultsView`.
//
//  The active search experience (`.searchable()`, results list, etc.) lives
//  in `SearchResultsView`, not here. This view is intentionally thin.
//

import SwiftUI

public struct SearchView: View {

    @State private var searchText = ""
    private let onSearch: (String) -> Void

    public init(onSearch: @escaping (String) -> Void) {
        self.onSearch = onSearch
    }

    public var body: some View {
        LandingView(searchText: $searchText, onSubmit: submit)
            .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        guard let query = Self.sanitize(searchText) else { return }
        // Clear before pushing so backing out of results lands on a fresh
        // empty field — the standard pattern (Apple Maps / Spotify / etc).
        searchText = ""
        onSearch(query)
    }

    /// Returns a clean query if the input should trigger a search, else nil.
    /// Pulled out of `submit()` so it's directly testable without spinning up
    /// the SwiftUI view hierarchy.
    static func sanitize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview("Landing → results push") {
    @Previewable @State var path = NavigationPath()

    NavigationStack(path: $path) {
        SearchView(onSearch: { query in
            path.append(SearchResultsRoute(query: query))
        })
        .navigationDestination(for: SearchResultsRoute.self) { route in
            Text(verbatim: "Results for: \(route.query)")
                .navigationTitle("Results")
        }
    }
}
