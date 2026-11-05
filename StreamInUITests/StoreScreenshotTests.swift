import XCTest

/// Captures the App Store and README screenshots from the live app (TMDB data).
///
/// Run by `scripts/store-screenshots.sh` through `Screenshots.xctestplan`, never by
/// CI: it needs a real TMDB key. The script picks the language with
/// `TEST_RUNNER_STREAMIN_SHOTS_LANGUAGE=en|es` and exports the attachments, named
/// in story order, as PNGs.
final class StoreScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The App Store story: search, a verdict at home, one abroad, the watchlist,
    /// then choosing your services. `90-` shots are for the README only.
    @MainActor
    func testStoreTour() throws {
        let tour = ScreenshotTour.current
        let app = tour.launch()
        sleep(8) // trending posters and the slot machine settle
        shot("01-landing")

        tour.search(tour.resultsQuery, in: app)
        shot("02-results")
        tour.back(in: app)

        // Saved in reverse, so the Watchlist (newest first) follows the story.
        for (movie, name) in [(tour.readABook, "90-read-a-book"), (tour.abroad, "04-abroad"), (tour.watchNow, "03-watch-now")] {
            tour.search(movie.query, in: app)
            tour.openDetails(movie.title, in: app)
            shot(name)
            tour.save(in: app)
            tour.back(in: app) // to the results
            tour.back(in: app) // to the landing
        }

        tour.openTab(tour.watchlistTab, in: app)
        sleep(4)
        shot("05-watchlist")

        app.terminate()
        let onboarding = tour.launch(onboarding: true)
        for service in ["Netflix", "Amazon Prime Video", "Disney Plus"] {
            let tile = onboarding.buttons.matching(NSPredicate(format: "label CONTAINS %@", service)).firstMatch
            XCTAssertTrue(tile.waitForExistence(timeout: 5), "No \(service) tile")
            tile.tap()
        }
        sleep(2)
        shot("06-services")
    }

    /// The README's demo: search → verdict → heart → Watchlist, paced for a
    /// screen recording (`simctl io recordVideo`). Takes no screenshots.
    @MainActor
    func testDemoTour() throws {
        let tour = ScreenshotTour.current
        let app = tour.launch()
        sleep(4)
        tour.search(tour.watchNow.query, in: app, typingPause: true)
        tour.openDetails(tour.watchNow.title, in: app)
        tour.save(in: app)
        sleep(1)
        tour.back(in: app)
        tour.back(in: app)
        tour.openTab(tour.watchlistTab, in: app)
        sleep(4)
    }

    @MainActor
    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
