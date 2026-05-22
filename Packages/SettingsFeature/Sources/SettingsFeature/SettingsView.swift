//
//  SettingsView.swift
//  SettingsFeature
//
//  Presented as a sheet from the search screen's gear icon. Hosts region,
//  language, and a `NavigationLink` row that pushes to the streaming-services
//  picker. We deliberately don't show provider rows inline — the picker is a
//  dedicated screen so the form stays scannable.
//

import SwiftUI
import Domain
import Preferences
import DesignSystem

public struct SettingsView: View {

    /// `@Bindable` instead of `@State`: the preferences object is owned by the
    /// App's composition root and passed in. `@Bindable` lets us project
    /// bindings (`$prefs.region`) onto the pickers without taking ownership.
    @Bindable var prefs: Preferences

    @State private var streamingServicesModel: StreamingServicesViewModel

    private let repository: MovieRepository
    private let imageURLBuilder: ImageURLBuilder

    @Environment(\.dismiss) private var dismiss

    public init(
        prefs: Preferences,
        repository: MovieRepository,
        imageURLBuilder: ImageURLBuilder
    ) {
        self.prefs = prefs
        self.repository = repository
        self.imageURLBuilder = imageURLBuilder
        _streamingServicesModel = State(
            initialValue: StreamingServicesViewModel(repository: repository, prefs: prefs)
        )
    }

    public var body: some View {
        Form {
            RegionSection(prefs: prefs)
            LanguageSection(prefs: prefs)
            StreamingServicesSection(
                prefs: prefs,
                model: streamingServicesModel,
                imageURLBuilder: imageURLBuilder
            )
        }
        .navigationTitle(Text(.settingsTitle))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(.settingsDone) { dismiss() }
            }
        }
        // Load the streaming-services catalog as soon as Settings appears so
        // the row summary can render provider logos (and the pushed picker
        // doesn't have to wait for a network round-trip). Re-fires when the
        // user changes their region.
        .task(id: prefs.region) {
            await streamingServicesModel.load(region: prefs.region)
        }
    }
}

// MARK: - Sections
//
// One struct per section. Each receives the `@Observable` preferences object and
// re-derives its own `@Bindable` so it can project bindings (`$prefs.region`)
// onto the picker. SwiftUI's per-property observation tracking means an unrelated
// section won't re-render when a different one's value changes.

private struct RegionSection: View {
    @Bindable var prefs: Preferences

    var body: some View {
        Section {
            Picker(selection: $prefs.region) {
                ForEach(Region.allKnown) { region in
                    Text(region.displayName).tag(region)
                }
            } label: {
                Text(.settingsRegionPicker)
            }
        } header: {
            Text(.settingsRegionHeader)
        } footer: {
            Text(.settingsRegionFooter)
        }
    }
}

private struct LanguageSection: View {
    @Bindable var prefs: Preferences
    @State private var showRestartAlert = false
    /// The language the user just picked in the UI but hasn't confirmed via
    /// the alert yet. Held in local state instead of being written straight to
    /// `prefs.language` so that nothing observable changes (TMDB requests,
    /// `AppleLanguages` override) until the user explicitly chooses Restart
    /// or Later. Cleared in `apply()` once the change is committed.
    @State private var pendingLanguage: Language?

    var body: some View {
        Section {
            Picker(selection: languageBinding) {
                ForEach(Language.allKnown) { language in
                    Text(language.displayName).tag(language)
                }
            } label: {
                Text(.settingsLanguagePicker)
            }
        } header: {
            Text(.settingsLanguageHeader)
        } footer: {
            Text(.settingsLanguageFooter)
        }
        .alert(Text(.settingsLanguageRestartTitle), isPresented: $showRestartAlert) {
            Button(.settingsLanguageRestartNow) {
                apply()
                exit(0)
            }
            Button(.settingsLanguageRestartLater, role: .cancel) {
                apply()
            }
        } message: {
            Text(.settingsLanguageRestartMessage)
        }
    }

    /// Drives the picker UI without mutating `prefs.language` directly.
    /// - get: always returns the currently-applied language so the picker UI
    ///   keeps showing the old value until the user confirms the alert. SwiftUI
    ///   re-renders after `set` updates `pendingLanguage`, and the picker reads
    ///   this getter again — which still returns `prefs.language`, so the
    ///   visible selection snaps back to the committed value.
    /// - set: picking a new language stashes it as pending and presents the
    ///   alert. Picking the already-applied language while a pending value
    ///   exists (i.e. the user changed their mind back) just clears the
    ///   pending state without re-presenting the alert.
    private var languageBinding: Binding<Language> {
        Binding(
            get: { prefs.language },
            set: { newValue in
                if newValue == prefs.language {
                    pendingLanguage = nil
                } else {
                    pendingLanguage = newValue
                    showRestartAlert = true
                }
            }
        )
    }

    /// Commits `pendingLanguage` to `prefs.language` and to the per-app
    /// `AppleLanguages` UserDefaults override (which iOS reads at next launch
    /// to pick the bundle's preferred localization). Bundles cache their
    /// preferred-localizations list at app start, so the UI only actually
    /// switches after a relaunch — the alert exists to make that explicit.
    private func apply() {
        guard let language = pendingLanguage else { return }
        prefs.language = language
        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        pendingLanguage = nil
    }
}

// MARK: - Streaming services row

/// Single-row section: "Streaming services" with a trailing summary and a
/// chevron via `NavigationLink`. The summary morphs through three states:
///   0 selected → "None" text
///   N selected, catalog still loading → "N selected" text
///   N selected, catalog loaded → strip of small provider icons + `+N` overflow
/// Tapping pushes `StreamingServicesView` for the actual multi-select UI.
private struct StreamingServicesSection: View {
    let prefs: Preferences
    let model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder

    var body: some View {
        Section {
            NavigationLink {
                StreamingServicesView(
                    model: model,
                    imageURLBuilder: imageURLBuilder
                )
                .environment(prefs)
            } label: {
                HStack {
                    Text(.settingsStreamingServicesRow)
                    Spacer()
                    StreamingServicesSummary(model: model, imageURLBuilder: imageURLBuilder)
                }
            }
        } header: {
            Text(.settingsSubscriptionsHeader)
        } footer: {
            Text(.settingsSubscriptionsBlurb)
        }
    }
}

/// Trailing summary on the Streaming Services row. Three states:
///   - 0 selected → "None" text.
///   - N selected, catalog still loading → "N selected" text (avoids a row
///     of gray placeholder squares while logos haven't arrived).
///   - N selected, catalog loaded → strip of provider logos with `+N` overflow.
private struct StreamingServicesSummary: View {
    let model: StreamingServicesViewModel
    let imageURLBuilder: ImageURLBuilder

    var body: some View {
        let selected = model.selectedProviders
        if selected.isEmpty {
            Text(.settingsStreamingServicesNone)
                .foregroundStyle(.secondary)
        } else if !model.hasLoadedAnyCatalog {
            Text(.settingsStreamingServicesCount(selected.count))
                .foregroundStyle(.secondary)
        } else {
            ProviderIconStrip(providers: selected, imageURLBuilder: imageURLBuilder)
        }
    }
}

// MARK: - Provider icon strip (Settings row trailing summary)

/// Compact horizontal strip of provider logos shown on the Settings
/// "Streaming services" row. Caps at 3 inline icons + a `+N` capsule —
/// the row shares space with the label and chevron so we stay conservative
/// on width.
private struct ProviderIconStrip: View {
    let providers: [WatchProvider]
    let imageURLBuilder: ImageURLBuilder

    /// Three logos comfortably fit on the smallest iPhone after the label
    /// ("Streaming services") + chevron. Anything beyond surfaces as `+N`.
    private static let maxInline = 3

    private var inlineProviders: [WatchProvider] {
        Array(providers.prefix(Self.maxInline))
    }

    private var overflow: Int {
        max(0, providers.count - Self.maxInline)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(inlineProviders) { provider in
                ProviderIcon(provider: provider, imageURLBuilder: imageURLBuilder)
            }
            if overflow > 0 {
                Text(verbatim: "+\(overflow)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: .capsule)
                    .accessibilityLabel(Text(.providerIconStripOverflowAccessibility(overflow)))
            }
        }
    }
}

private struct ProviderIcon: View {
    let provider: WatchProvider
    let imageURLBuilder: ImageURLBuilder

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = LogoSize.small

    var body: some View {
        ProviderLogo(
            url: provider.logoPath.flatMap {
                imageURLBuilder.url(for: $0, size: .providerLogo)
            },
            providerName: provider.name,
            size: size,
            cornerRadius: Radius.small
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            prefs: Preferences(),
            repository: PreviewMovieRepository(),
            imageURLBuilder: PreviewImageURLBuilder()
        )
    }
}

private struct PreviewMovieRepository: MovieRepository {
    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        fatalError("not used in preview")
    }
    func movie(id: MovieID) async throws -> Movie {
        fatalError("not used in preview")
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        fatalError("not used in preview")
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        AvailabilityBundle(
            regional: WatchAvailability(
                movieID: id, region: region,
                subscription: [], rent: [], buy: [], free: [], externalLink: nil
            ),
            global: GlobalWatchAvailability(movieID: id, subscription: [])
        )
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        [
            WatchProvider(id: ProviderID(8), name: "Netflix", logoPath: nil, priority: 1),
            WatchProvider(id: ProviderID(9), name: "Amazon Prime Video", logoPath: nil, priority: 2),
            WatchProvider(id: ProviderID(337), name: "Disney Plus", logoPath: nil, priority: 3)
        ]
    }
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
