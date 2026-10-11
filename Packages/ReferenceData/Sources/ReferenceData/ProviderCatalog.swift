//
//  ProviderCatalog.swift
//  ReferenceData
//
//  App-wide reference data for streaming providers: the name and logo of
//  every provider TMDB knows about, worldwide and per region.
//
//  This is reference data, not a cache. It has no expiry: it's loaded once
//  at launch by the composition root and read synchronously afterwards, so
//  screens that list providers render complete on their first frame instead
//  of flashing a loading state. A scope that hasn't been loaded yet (e.g. a
//  region the user just switched to) is fetched on demand.
//

import Observation
import Domain

@Observable
@MainActor
public final class ProviderCatalog {

    /// Loaded catalogs keyed by scope. The `nil` key is the worldwide catalog.
    private var catalogs: [Region?: [WatchProvider]] = [:]
    /// Id → provider across every loaded scope. Worldwide entries win, so a
    /// provider's metadata doesn't depend on which region happened to load first.
    private var index: [ProviderID: WatchProvider] = [:]
    private var inFlight: [Region?: Task<Void, Never>] = [:]

    /// Failure of the most recent load, cleared by the next successful one.
    public private(set) var lastError: MovieError?

    private let repository: MovieRepository

    public init(repository: MovieRepository) {
        self.repository = repository
    }

    /// Providers active in `region` (`nil` = worldwide), sorted by TMDB display
    /// priority, or `nil` if that scope hasn't been loaded yet.
    public func providers(in region: Region?) -> [WatchProvider]? {
        catalogs[region]
    }

    /// Metadata for one provider, from whichever loaded scope knows it.
    public func provider(id: ProviderID) -> WatchProvider? {
        index[id]
    }

    public func isLoading(_ region: Region?) -> Bool {
        inFlight[region] != nil
    }

    /// Ensures the worldwide catalog and `region`'s catalog are loaded.
    ///
    /// Scopes that are already loaded are skipped, and concurrent callers share
    /// one request per scope, so every screen that needs the data can call this
    /// on appearance without coordinating with the launch preload.
    public func load(region: Region) async {
        let pending = [loadTask(for: nil), loadTask(for: region)].compactMap { $0 }
        for task in pending {
            await task.value
        }
    }

    private func loadTask(for scope: Region?) -> Task<Void, Never>? {
        if catalogs[scope] != nil { return nil }
        if let running = inFlight[scope] { return running }

        let task = Task {
            do {
                let providers = try await repository.allProviders(in: scope)
                store(providers, for: scope)
                lastError = nil
            } catch let error as MovieError {
                lastError = error
            } catch {
                lastError = .unknown
            }
            inFlight[scope] = nil
        }
        inFlight[scope] = task
        return task
    }

    private func store(_ providers: [WatchProvider], for scope: Region?) {
        catalogs[scope] = providers
        for provider in providers where scope == nil || index[provider.id] == nil {
            index[provider.id] = provider
        }
    }
}
