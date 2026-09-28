//
//  SettingsToolbar.swift
//  StreamIn
//
//  Gear button on the first screen of each tab. Flips the `showingSettings`
//  binding owned by `RootView`, which presents the Settings sheet. Pushed
//  screens don't show it: their toolbar is for actions about their content.
//

import SwiftUI
import DesignSystem

struct SettingsToolbar: ToolbarContent {
    @Binding var showingSettings: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: Symbol.gear) {
                showingSettings = true
            }
            // The TabView's `.tint(AppPalette.accent)` propagates down the
            // view tree to toolbar items by default. The gear is chrome, not
            // a primary action — override back to the system primary color
            // so only the active tab tab indicator carries the accent.
            .tint(.primary)
        }
    }
}
