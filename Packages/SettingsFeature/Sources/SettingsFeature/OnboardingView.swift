//
//  OnboardingView.swift
//  SettingsFeature
//
//  First-launch picker that prompts the user to declare which streaming
//  services they pay for. Wraps `StreamingServicesView` (the same multi-
//  select used from Settings) with a welcome header pinned at the top of
//  the safe area and a single "Done" toolbar button.
//
//  Triggering rule lives in the App target's `RootView` — see
//  `StreamInApp.swift`. During the test phase the rule is "show whenever
//  the user has no subscriptions"; once shipping, swap it for a
//  first-launch flag persisted in `Preferences`. See CLAUDE.md "TODO:
//  onboarding trigger" for the migration.
//

import SwiftUI
import Domain
import Preferences
import ReferenceData
import DesignSystem

public struct OnboardingView: View {

    @State private var model: StreamingServicesViewModel
    private let prefs: Preferences
    private let imageURLBuilder: ImageURLBuilder

    @Environment(\.dismiss) private var dismiss

    public init(
        prefs: Preferences,
        catalog: ProviderCatalog,
        imageURLBuilder: ImageURLBuilder
    ) {
        self.prefs = prefs
        self.imageURLBuilder = imageURLBuilder
        _model = State(
            initialValue: StreamingServicesViewModel(catalog: catalog, prefs: prefs)
        )
    }

    public var body: some View {
        NavigationStack {
            StreamingServicesView(
                model: model,
                imageURLBuilder: imageURLBuilder,
                title: .onboardingNavTitle
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                OnboardingHeader()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.onboardingDone) { dismiss() }
                }
            }
            .task(id: prefs.region) {
                await model.load()
            }
            .environment(prefs)
        }
    }
}

// MARK: - Welcome header

/// Pinned above the picker list. Brief, scannable — the user is here to
/// pick services, not read prose.
private struct OnboardingHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            // Icon uses Dynamic Type via `.largeTitle`, so it grows with
            // accessibility text sizes instead of staying fixed at 44pt.
            Image(systemName: Symbol.popcornFill)
                .font(.largeTitle)
                .foregroundStyle(AppPalette.accent)
                .accessibilityHidden(true)
            Text(.onboardingHeaderTitle)
                .font(.title3)
                .bold()
            Text(.onboardingHeaderSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        // `.bar` material matches the visual treatment iOS uses for
        // top-pinned content above a List, blending with the nav bar.
        .background(.bar)
    }
}
