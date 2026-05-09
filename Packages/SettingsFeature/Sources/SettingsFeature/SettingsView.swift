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
import Preferences

public struct SettingsView: View {

    /// `@Bindable` instead of `@State`: the preferences object is owned by the
    /// App's composition root and passed in. `@Bindable` lets us project
    /// bindings (`$prefs.region`) onto the pickers without taking ownership.
    @Bindable var prefs: Preferences
    @Environment(\.dismiss) private var dismiss

    public init(prefs: Preferences) {
        self.prefs = prefs
    }

    public var body: some View {
        Form {
            RegionSection(prefs: prefs)
            LanguageSection(prefs: prefs)
            SubscriptionsSection()
        }
        .navigationTitle(Text(.settingsTitle))
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(.settingsDone) { dismiss() }
            }
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

    var body: some View {
        Section {
            Picker(selection: $prefs.language) {
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
    }
}

private struct SubscriptionsSection: View {
    var body: some View {
        Section {
            Text(.settingsSubscriptionsBlurb)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(.settingsSubscriptionsComingSoon)
                .font(.caption)
                .foregroundStyle(.tertiary)
        } header: {
            Text(.settingsSubscriptionsHeader)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(prefs: Preferences())
    }
}
