//
//  StreamingServicesSheet.swift
//  SettingsFeature
//
//  The streaming-services picker on its own, as a sheet. Lets screens outside
//  Settings (e.g. Details when no services are picked yet) take the user
//  straight to the one setting they need, instead of the whole Settings form.
//

import SwiftUI
import Domain
import Preferences
import ReferenceData

public struct StreamingServicesSheet: View {

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
            StreamingServicesView(model: model, imageURLBuilder: imageURLBuilder)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(.settingsDone) { dismiss() }
                    }
                }
                .task(id: prefs.region) {
                    await model.load()
                }
                .environment(prefs)
        }
    }
}
