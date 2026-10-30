import Foundation
import Domain

/// Holds every availability request for `gatedRegion` until `release()`, so a
/// test can make an old region's answer land after the new region's. Other
/// regions answer at once with RTVE Play free.
actor GatedMovieRepository: MovieRepository {
    let gatedRegion: Region

    private var gate: CheckedContinuation<Void, Never>?
    private var arrivalWaiter: CheckedContinuation<Void, Never>?
    private var gatedRequestArrived = false

    init(gatedRegion: Region) {
        self.gatedRegion = gatedRegion
    }

    func availabilities(for id: MovieID, in region: Region) async throws -> AvailabilityBundle {
        guard region == gatedRegion else {
            return .fixture(id, region: region, free: [.rtvePlay])
        }
        gatedRequestArrived = true
        arrivalWaiter?.resume()
        arrivalWaiter = nil
        await withCheckedContinuation { gate = $0 }
        return .fixture(id, region: region)
    }

    /// Returns once a request for `gatedRegion` is being held.
    func waitForGatedRequest() async {
        guard !gatedRequestArrived else { return }
        await withCheckedContinuation { arrivalWaiter = $0 }
    }

    func release() {
        gate?.resume()
        gate = nil
    }

    func searchMovies(query: String, page: Int) async throws -> SearchPage { throw MovieError.unknown }
    func trendingMovies() async throws -> [Movie] { throw MovieError.unknown }
    func movie(id: MovieID) async throws -> Movie { throw MovieError.unknown }
    func availability(for id: MovieID, in region: Region) async throws -> WatchAvailability { throw MovieError.unknown }
    func allProviders(in region: Region?) async throws -> [WatchProvider] { [] }
}
