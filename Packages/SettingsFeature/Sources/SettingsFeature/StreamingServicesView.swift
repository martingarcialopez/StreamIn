//
//  StreamingServicesView.swift
//  SettingsFeature
//
//  The "Streaming services" picker. Reached from a row in Settings; replaces
//  the older inline curated-list + separate "More providers" sheet pair.
//
//  Layout sections (all in a single `List`, top to bottom):
//
//  1. **Your subscriptions** — every currently-selected provider, with the
//     check shown so deselection is one tap. Hidden when nothing is selected.
//  2. **Worldwide toggle** — switches the "Available" section between
//     home-region scope and the full TMDB catalog. Off by default.
//  3. **Available** — every provider in the current scope minus the ones
//     already in "Your subscriptions" (to avoid duplicated rows). Section
//     header surfaces the scope so the user always knows what they're
//     browsing.
//
//  `.searchable` filters both data sections.
//

import SwiftUI
import Domain
import Preferences
import DesignSystem

// MARK: - View model

@Observable
@MainActor
public final class StreamingServicesViewModel {

    private let repository: MovieRepository
    private let prefs: Preferences

    /// User-flipped: false = home region, true = worldwide catalog.
    var showWorldwide = false
    var searchText = ""

    private(set) var regionalCatalog: [WatchProvider] = []
    private(set) var worldwideCatalog: [WatchProvider] = []
    private(set) var isLoading = false
    private(set) var loadError: MovieError?

    public init(repository: MovieRepository, prefs: Preferences) {
        self.repository = repository
        self.prefs = prefs
    }

    /// Loads both catalogs in parallel so:
    ///   - the "Your subscriptions" section can resolve names/logos for
    ///     providers chosen via the worldwide toggle, even when worldwide
    ///     isn't the active scope;
    ///   - flipping the worldwide toggle is instant (no second round-trip).
    public func load(region: Region) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let regionalTask = repository.allProviders(in: region)
            async let worldwideTask = repository.allProviders(in: nil)
            let (regional, worldwide) = try await (regionalTask, worldwideTask)
            self.regionalCatalog = regional
            self.worldwideCatalog = worldwide
            self.loadError = nil
        } catch let movieError as MovieError {
            self.loadError = movieError
        } catch {
            self.loadError = .unknown
        }
    }

    // MARK: - Derived

    public var selectedCount: Int {
        prefs.subscribedProviderIDs.count
    }

    /// Selected providers, with metadata resolved from either catalog.
    /// **Not** filtered by `searchText` — the Settings row summary and the
    /// picker's "Your subscriptions" section both rely on this being the
    /// complete list. Search only narrows the "Available" section.
    public var selectedProviders: [WatchProvider] {
        let ids = prefs.subscribedProviderIDs
        return ids.map { id in
            regionalCatalog.first(where: { $0.id == id })
                ?? worldwideCatalog.first(where: { $0.id == id })
                ?? WatchProvider(id: id, name: "Provider \(id.rawValue)", logoPath: nil, priority: Int.max)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// True once at least one of the two catalogs has loaded — i.e. the
    /// metadata in `selectedProviders` is real and not the
    /// `"Provider <id>"` placeholder. The Settings row uses this to choose
    /// between a count summary and the icon strip so the user never sees
    /// a row full of gray placeholder squares.
    public var hasLoadedAnyCatalog: Bool {
        !regionalCatalog.isEmpty || !worldwideCatalog.isEmpty
    }

    /// First-load state: spinning a `ProgressView` is appropriate. Used by
    /// the picker's "Available" section to decide between a spinner and the
    /// regular content/empty branches.
    public var isInitialLoad: Bool {
        isLoading && regionalCatalog.isEmpty && worldwideCatalog.isEmpty
    }

    /// Catalog under the current scope. Excludes already-selected providers
    /// (those live in the "Your subscriptions" section above to avoid
    /// duplicated rows) and applies the search filter.
    public var availableProviders: [WatchProvider] {
        let base = showWorldwide ? worldwideCatalog : regionalCatalog
        let selectedIDs = prefs.subscribedProviderIDs
        return base
            .filter { !selectedIDs.contains($0.id) }
            .filter(matchesSearch)
    }

    public func isSubscribed(_ id: ProviderID) -> Bool {
        prefs.subscribedProviderIDs.contains(id)
    }

    public func toggle(_ id: ProviderID) {
        var ids = prefs.subscribedProviderIDs
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        prefs.subscribedProviderIDs = ids
    }

    private func matchesSearch(_ provider: WatchProvider) -> Bool {
        searchText.isEmpty || provider.name.localizedStandardContains(searchText)
    }
}

// MARK: - View

struct StreamingServicesView: View {

    /// `@Bindable` (not `@State`) because the parent (`SettingsView` or
    /// `OnboardingView`) owns the model. We just observe its properties
    /// and project bindings (`$model.searchText`, `$model.showWorldwide`).
    @Bindable var model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder
    /// Injected nav title so the same picker can serve Settings ("Streaming
    /// Services") and Onboarding ("Welcome") without duplicating the list.
    let title: LocalizedStringResource

    @Environment(Preferences.self) private var prefs

    init(
        model: StreamingServicesViewModel,
        imageURLBuilder: ImageURLBuilder,
        title: LocalizedStringResource = .settingsStreamingServicesTitle
    ) {
        self.model = model
        self.imageURLBuilder = imageURLBuilder
        self.title = title
    }

    var body: some View {
        List {
            YourSubscriptionsSection(model: model, imageURLBuilder: imageURLBuilder)
            WorldwideToggleSection(model: model)
            AvailableProvidersSection(model: model, imageURLBuilder: imageURLBuilder, region: prefs.region)
        }
        .navigationTitle(Text(title))
        .toolbarTitleDisplayMode(.inline)
        .searchable(
            text: $model.searchText,
            prompt: Text(.settingsMoreProvidersSearchPrompt)
        )
        // No `.task` here: the parent (SettingsView or OnboardingView) owns
        // the model and triggers loading on its own appearance, so the
        // catalog is ready by the time the user gets here.
    }
}

// MARK: - Picker sections

/// "Your subscriptions" — every selected provider, with checkmark for
/// deselect. Hidden when nothing is selected.
private struct YourSubscriptionsSection: View {
    @Bindable var model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder

    var body: some View {
        let selected = model.selectedProviders
        if !selected.isEmpty {
            Section {
                ForEach(selected) { provider in
                    ProviderToggleRow(
                        provider: provider,
                        isSubscribed: true,
                        imageURLBuilder: imageURLBuilder,
                        toggle: { model.toggle(provider.id) }
                    )
                }
            } header: {
                Text(.settingsStreamingServicesYourSubs)
            }
        }
    }
}

/// "Show providers worldwide" toggle — switches `AvailableProvidersSection`
/// between home-region and worldwide scope.
private struct WorldwideToggleSection: View {
    @Bindable var model: StreamingServicesViewModel

    var body: some View {
        Section {
            Toggle(isOn: $model.showWorldwide) {
                Text(.settingsMoreProvidersWorldwideToggle)
            }
        } footer: {
            Text(.settingsStreamingServicesWorldwideFooter)
        }
    }
}

/// "Available in <region>" / "Available worldwide" — scoped catalog with
/// selected providers filtered out (they live in `YourSubscriptionsSection`).
private struct AvailableProvidersSection: View {
    @Bindable var model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder
    let region: Region

    var body: some View {
        Section {
            if model.isInitialLoad {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if model.availableProviders.isEmpty {
                Text(.settingsMoreProvidersEmpty)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.availableProviders) { provider in
                    ProviderToggleRow(
                        provider: provider,
                        isSubscribed: false,
                        imageURLBuilder: imageURLBuilder,
                        toggle: { model.toggle(provider.id) }
                    )
                }
            }
        } header: {
            Text(model.showWorldwide
                 ? .settingsStreamingServicesAvailableWorldwide
                 : .settingsStreamingServicesAvailableInRegion(region.displayName))
        }
    }
}

// MARK: - Row

/// Logo + name + trailing checkmark. Tappable across the whole row.
struct ProviderToggleRow: View {
    let provider: WatchProvider
    let isSubscribed: Bool
    let imageURLBuilder: ImageURLBuilder
    let toggle: () -> Void

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = LogoSize.medium

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                ProviderLogo(
                    url: provider.logoPath.flatMap {
                        imageURLBuilder.url(for: $0, size: .providerLogo)
                    },
                    providerName: provider.name,
                    size: logoSize,
                    cornerRadius: Radius.medium
                )
                .accessibilityHidden(true)

                Text(provider.name)
                    .foregroundStyle(.primary)

                Spacer()

                if isSubscribed {
                    Image(systemName: Symbol.checkmark)
                        .foregroundStyle(.tint)
                        .accessibilityLabel(Text(.providerRowSubscribedAccessibility))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
