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
