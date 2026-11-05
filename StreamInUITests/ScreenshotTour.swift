import XCTest

/// One language's setup: launch arguments, the movies, and the labels the test taps.
struct ScreenshotTour {
    struct Movie {
        /// What to type in the search field.
        let query: String
        /// How the result row's label begins.
        let title: String
    }

    let languages: String
    let locale: String
    let languageCode: String
    let regionCode: String
    let searchPrompt: String
    let addToWatchlist: String
    let watchlistTab: String
    let resultsQuery: String
    let watchNow: Movie
    let abroad: Movie
    let readABook: Movie

    static let english = ScreenshotTour(
        languages: "(en)", locale: "en_GB", languageCode: "en-GB", regionCode: "GB",
        searchPrompt: "Search a movie", addToWatchlist: "Add to Watchlist", watchlistTab: "Watchlist",
        resultsQuery: "Night",
        watchNow: Movie(query: "Spirited Away", title: "Spirited Away"),
        abroad: Movie(query: "Whiplash", title: "Whiplash"),
        readABook: Movie(query: "Greyhound", title: "Greyhound")
    )

    static let spanish = ScreenshotTour(
        languages: "(es)", locale: "es_ES", languageCode: "es-ES", regionCode: "ES",
        searchPrompt: "Busca una película", addToWatchlist: "Añadir a Favoritos", watchlistTab: "Favoritos",
        resultsQuery: "Noche",
        watchNow: Movie(query: "El viaje de Chihiro", title: "El viaje de Chihiro"),
        abroad: Movie(query: "Whiplash", title: "Whiplash"),
        readABook: Movie(query: "Greyhound", title: "Greyhound")
    )

    static var current: ScreenshotTour {
        ProcessInfo.processInfo.environment["STREAMIN_SHOTS_LANGUAGE"] == "es" ? spanish : english
    }

    @MainActor
    func launch(onboarding: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", languages,
            "-AppleLocale", locale,
            "-settings.language.code", languageCode,
            "-settings.region.code", regionCode,
            "-settings.hasCompletedOnboarding", onboarding ? "NO" : "YES",
            // JSON as <hex>: "[]", or "[8,9,337]" (Netflix, Prime Video, Disney Plus).
            "-settings.subscribedProviders.ids", onboarding ? "<5b5d>" : "<5b382c392c3333375d>",
        ]
        app.launchEnvironment["STREAMIN_IN_MEMORY_WATCHLIST"] = "1"
        app.launch()
        return app
    }

    /// Types a query into the landing's search field and waits for the results.
    @MainActor
    func search(_ query: String, in app: XCUIApplication, typingPause: Bool = false) {
        let field = app.textFields[searchPrompt].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10), "No search field")
        field.tap()
        if let current = field.value as? String, !current.isEmpty, current != searchPrompt {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        if typingPause {
            for character in query {
                field.typeText(String(character))
                usleep(120_000)
            }
            field.typeText("\n")
        } else {
            field.typeText(query + "\n")
        }
        sleep(6) // rows fill in with their availability and posters
    }

    /// Opens the first result whose label begins with `title`.
    @MainActor
    func openDetails(_ title: String, in app: XCUIApplication) {
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "No result row for \(title)")
        row.tap()
        sleep(6) // backdrop, verdict and the globe
    }

    /// Taps the heart on Details.
    @MainActor
    func save(in app: XCUIApplication) {
        let heart = app.buttons[addToWatchlist].firstMatch
        XCTAssertTrue(heart.waitForExistence(timeout: 5), "No heart")
        heart.tap()
        sleep(1)
    }

    /// Pops one screen.
    @MainActor
    func back(in app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
    }

    /// Taps a tab by its title: in the tab bar on iPhone, the top bar on iPad.
    @MainActor
    func openTab(_ title: String, in app: XCUIApplication) {
        let tabBarItem = app.tabBars.buttons[title].firstMatch
        let button = tabBarItem.exists ? tabBarItem : app.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "No \(title) tab")
        button.tap()
    }
}
