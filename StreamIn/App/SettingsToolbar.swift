//
//  SettingsToolbar.swift
//  StreamIn
//
//  Gear button used by every tab's NavigationStack toolbar. Flips the
//  `showingSettings` binding owned by `RootView`, which presents the
//  Settings sheet.
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
        }
    }
}
