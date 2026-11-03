//
//  RegionPickerView.swift
//  SettingsFeature
//
//  The home-region picker, pushed from Settings. TMDB covers ~150
//  countries, too many for a menu, so this is a searchable list: the current
//  region pinned on top, then every region by name. Picking one goes back.
//

import SwiftUI
import Domain
import Preferences
import ReferenceData
import DesignSystem

struct RegionPickerView: View {

    @Bindable var model: RegionPickerViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if model.isInitialLoad {
                LoadingRow()
                    .cinemaRow()
            } else if let error = model.loadError {
                LoadFailedRow(error: error) {
                    Task { await model.load() }
                }
                .cinemaRow()
            } else {
                if model.showsSelectedRegion {
                    Section {
                        RegionRow(region: model.selectedRegion, isSelected: true) {
                            dismiss()
                        }
                    } header: {
                        Text(.settingsRegionSelectedHeader)
                    }
                    .cinemaRow()
                }
                Section {
                    ForEach(model.matchingRegions) { region in
                        RegionRow(region: region, isSelected: region == model.selectedRegion) {
                            model.select(region)
                            dismiss()
                        }
                    }
                } header: {
                    if model.showsSelectedRegion {
                        Text(.settingsRegionAllHeader)
                    }
                }
                .cinemaRow()
            }
        }
        .overlay {
            if !model.searchText.isEmpty && model.matchingRegions.isEmpty && model.loadError == nil {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
        .cinemaBackground()
        .navigationTitle(Text(.settingsRegionPicker))
        .toolbarTitleDisplayMode(.inline)
        .searchable(text: $model.searchText, prompt: Text(.settingsRegionSearchPrompt))
        .task {
            await model.load()
        }
    }
}

// MARK: - Rows

/// Flag + country name, with a checkmark on the selected one.
private struct RegionRow: View {
    let region: Region
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.comfortable) {
                Text(region.flag)
                    .accessibilityHidden(true)
                Text(region.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: Symbol.checkmark)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LoadingRow: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

private struct LoadFailedRow: View {
    let error: MovieError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(.settingsRegionLoadFailed)
            } icon: {
                Image(systemName: Symbol.exclamationmarkTriangle)
            }
        } description: {
            Text(error.userMessage)
        } actions: {
            Button(.settingsRegionRetry, action: retry)
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        RegionPickerView(model: previewModel(PreviewMovieRepository()))
    }
}

#Preview("Failed") {
    NavigationStack {
        RegionPickerView(model: previewModel(PreviewMovieRepository(failure: .offline)))
    }
}

@MainActor
private func previewModel(_ repository: PreviewMovieRepository) -> RegionPickerViewModel {
    let prefs = Preferences(
        defaultRegion: Region(code: "IT"),
        defaults: UserDefaults(suiteName: "RegionPickerView.preview")!
    )
    return RegionPickerViewModel(catalog: RegionCatalog(repository: repository), prefs: prefs)
}

private struct PreviewMovieRepository: MovieRepository {
    var failure: MovieError?

    func searchMovies(query: String, page: Int) async throws -> SearchPage {
        fatalError("not used in preview")
    }
    func movie(id: MovieID) async throws -> Movie {
        fatalError("not used in preview")
    }
    func trendingMovies() async throws -> [Movie] {
        fatalError("not used in preview")
    }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability {
        fatalError("not used in preview")
    }
    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        fatalError("not used in preview")
    }
    func allProviders(in region: Region?) async throws -> [WatchProvider] {
        fatalError("not used in preview")
    }
    func watchRegions() async throws -> [Region] {
        if let failure { throw failure }
        return ["AR", "AU", "BR", "CA", "DE", "ES", "FR", "GB", "IT", "JP", "MX", "US"]
            .map(Region.init(code:))
    }
}
