//
//  SettingsView.swift
//  SettingsFeature
//
//  Presented as a sheet from the search screen's gear icon. Shape: a Form with
//  the region picker (working) and a placeholder section for streaming-service
//  subscription preferences (will be implemented once we have a per-region
//  provider catalog). Includes a Done button in the toolbar to dismiss.
//

import SwiftUI
import Domain

public struct SettingsView: View {

    /// `@Bindable` instead of `@State`: the model is owned by the App's
    /// composition root and passed in here. `@Bindable` lets us project
    /// bindings (`$model.region`) onto the picker without taking ownership.
    @Bindable var model: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    public init(model: SettingsViewModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            RegionSection(model: model)
            LanguageSection(model: model)
            SubscriptionsSection()
        }
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - Sections
//
// One struct per section. Each receives the `@Observable` model and re-derives
// its own `@Bindable` so it can project bindings (`$model.region`) onto the
// picker. SwiftUI's per-property observation tracking means an unrelated
// section won't re-render when a different one's value changes.

private struct RegionSection: View {
    @Bindable var model: SettingsViewModel

    var body: some View {
        Section {
            Picker("Region", selection: $model.region) {
                ForEach(Region.allKnown, id: \.code) { region in
                    Text(region.displayName).tag(region)
                }
            }
        } header: {
            Text("Region")
        } footer: {
            Text("Determines which streaming services appear for each movie.")
        }
    }
}

private struct LanguageSection: View {
    @Bindable var model: SettingsViewModel

    var body: some View {
        Section {
            Picker("Language", selection: $model.language) {
                ForEach(Language.allKnown, id: \.code) { language in
                    Text(language.displayName).tag(language)
                }
            }
        } header: {
            Text("Language")
        } footer: {
            Text("Controls the language of movie titles, descriptions, and poster art returned by TMDB.")
        }
    }
}

private struct SubscriptionsSection: View {
    var body: some View {
        Section {
            Text("Tell us which streaming services you subscribe to so we can highlight them in search results.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } header: {
            Text("My subscriptions")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(model: SettingsViewModel())
    }
}
