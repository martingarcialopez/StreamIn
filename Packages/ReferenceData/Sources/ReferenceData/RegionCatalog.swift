//
//  RegionCatalog.swift
//  ReferenceData
//
//  App-wide reference data for regions: every country TMDB has streaming
//  availability for, which is what the home-region picker offers.
//
//  Like `ProviderCatalog`, this is reference data, not a cache: loaded once
//  at launch and read synchronously afterwards, with no expiry.
//

import Observation
import Domain

@Observable
@MainActor
public final class RegionCatalog {

    /// Every region TMDB covers, sorted by name in the interface language, or
    /// `nil` until the first load succeeds.
    public private(set) var regions: [Region]?

    /// Failure of the most recent load, cleared by the next successful one.
    public private(set) var lastError: MovieError?

    private var inFlight: Task<Void, Never>?

    private let repository: MovieRepository

    public init(repository: MovieRepository) {
        self.repository = repository
    }

    public var isLoading: Bool {
        inFlight != nil
    }

    /// Loads the region list unless it's already loaded. Concurrent callers
    /// share one request, so any screen can call this on appearance.
    public func load() async {
        if regions != nil { return }
        if let running = inFlight {
            await running.value
            return
        }

        let task = Task {
            do {
                let loaded = try await repository.watchRegions()
                regions = loaded.sorted { lhs, rhs in
                    lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
                }
                lastError = nil
            } catch let error as MovieError {
                lastError = error
            } catch {
                lastError = .unknown
            }
            inFlight = nil
        }
        inFlight = task
        await task.value
    }
}
