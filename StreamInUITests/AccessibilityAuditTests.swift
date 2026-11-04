//
//  AccessibilityAuditTests.swift
//  StreamInUITests
//
//  Runs Xcode's accessibility audit (labels, contrast, hit regions, traits,
//  clipped text, Dynamic Type) on every screen, at the default text size and
//  at the largest accessibility size. The app reads canned data
//  (`STREAMIN_UI_TEST_FIXTURES=1`, see `FixtureMovieRepository`), seen from
//  Spain in English, so the screens are the same on every run and on CI.
//

import XCTest

final class AccessibilityAuditTests: XCTestCase {

    override func setUp() {
        // Every issue on a screen is reported, not only the first.
        continueAfterFailure = true
    }

    @MainActor
    func testOnboardingSearchDetailsAndWatchlist() throws {
        try onboardingSearchDetailsAndWatchlist(textSize: .default)
    }

    @MainActor
    func testOnboardingSearchDetailsAndWatchlistAtAX5() throws {
        try onboardingSearchDetailsAndWatchlist(textSize: .ax5)
    }

    @MainActor
    func testWatchlistEmptyAndSettings() throws {
        try watchlistEmptyAndSettings(textSize: .default)
    }

    @MainActor
    func testWatchlistEmptyAndSettingsAtAX5() throws {
        try watchlistEmptyAndSettings(textSize: .ax5)
    }

    // MARK: - Flows

    /// Onboarding, then Search: Landing, results, and Details for each verdict.
    /// Saving a film on the way fills the Watchlist, audited last.
    @MainActor
    private func onboardingSearchDetailsAndWatchlist(textSize: TextSize) throws {
        let app = launch(onboarded: false, subscriptions: [], textSize: textSize)

        let netflix = app.buttons["Netflix"].firstMatch
        XCTAssertTrue(netflix.waitForExistence(timeout: 10), "Onboarding should list Netflix")
        try auditScrolling(app, "Onboarding", textSize)
        scrollTo(netflix, in: app).tap()
        app.navigationBars.buttons["Done"].tap()

        let searchField = app.textFields["Search a movie"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        try audit(app, "Landing", textSize)

        searchField.tap()
        searchField.typeText("film\n")
        XCTAssertTrue(row(app, titled: "Inception").waitForExistence(timeout: 10))
        try auditScrolling(app, "Search results", textSize)

        // Watch now, on your services abroad, free at home, read a book.
        for title in ["Inception", "Dune", "Paddington", "Amélie"] {
            scrollTo(row(app, titled: title), in: app).tap()
            let heart = app.buttons["Add to Watchlist"]
            XCTAssertTrue(heart.waitForExistence(timeout: 10), "Details of \(title)")
            try auditScrolling(app, "Details: \(title)", textSize)
            if title == "Inception" {
                heart.tap()
                XCTAssertTrue(app.buttons["Remove from Watchlist"].waitForExistence(timeout: 5))
            }
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        app.tabBars.buttons["Watchlist"].tap()
        XCTAssertTrue(row(app, titled: "Inception").waitForExistence(timeout: 10))
        try audit(app, "Watchlist, filled", textSize)
    }

    /// The empty Watchlist, then Settings and the two screens it pushes.
    @MainActor
    private func watchlistEmptyAndSettings(textSize: TextSize) throws {
        let app = launch(onboarded: true, subscriptions: [8], textSize: textSize)

        app.tabBars.buttons["Watchlist"].tap()
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        try audit(app, "Watchlist, empty", textSize)

        settings.tap()
        let region = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Region'")).firstMatch
        XCTAssertTrue(region.waitForExistence(timeout: 10))
        try auditScrolling(app, "Settings", textSize)

        scrollTo(region, in: app).tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 10))
        try audit(app, "Region picker", textSize)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // At accessibility sizes Language pushes a list rather than opening a
        // menu; picking from it still asks to restart.
        if textSize == .ax5 {
            let language = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Language'")).firstMatch
            scrollTo(language, in: app).tap()
            let spanish = app.buttons.containing(NSPredicate(format: "label BEGINSWITH[c] 'español'")).firstMatch
            XCTAssertTrue(spanish.waitForExistence(timeout: 10))
            try audit(app, "Language list", textSize)
            spanish.tap()
            let later = app.alerts.buttons["Later"]
            XCTAssertTrue(later.waitForExistence(timeout: 5), "Picking a language asks to restart")
            later.tap()
        }

        let services = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Streaming services'")).firstMatch
        scrollTo(services, in: app).tap()
        XCTAssertTrue(app.buttons["Netflix"].firstMatch.waitForExistence(timeout: 10))
        try auditScrolling(app, "Streaming services", textSize)
    }

    // MARK: - Launch and navigation

    enum TextSize {
        case `default`
        /// The largest accessibility size, AX5.
        case ax5
    }

    @MainActor
    private func launch(onboarded: Bool, subscriptions: [Int], textSize: TextSize) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["STREAMIN_UI_TEST_FIXTURES"] = "1"
        app.launchEnvironment["STREAMIN_IN_MEMORY_WATCHLIST"] = "1"
        // Arguments land in UserDefaults' argument domain, over whatever an
        // earlier run saved. The services are a JSON array of IDs, as data.
        let ids = subscriptions.map(String.init).joined(separator: ",")
        let idsHex = Data("[\(ids)]".utf8).map { ($0 < 0x10 ? "0" : "") + String($0, radix: 16) }.joined()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_GB",
            "-settings.region.code", "ES",
            "-settings.language.code", "en-GB",
            "-settings.hasCompletedOnboarding", onboarded ? "YES" : "NO",
            "-settings.subscribedProviders.ids", "<\(idsHex)>",
        ]
        if textSize == .ax5 {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    /// A search or Watchlist row: one element whose label starts with the title.
    @MainActor
    private func row(_ app: XCUIApplication, titled title: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    /// Scrolls until `element` is on screen: at AX5, lists hold few rows.
    @MainActor
    @discardableResult
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        for _ in 0..<10 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
        return element
    }

    // MARK: - Audit

    /// Audits a scrolling screen page by page, so what starts below the fold
    /// is measured whole on a later page, then scrolls back to the top.
    @MainActor
    private func auditScrolling(_ app: XCUIApplication, _ screen: String, _ textSize: TextSize) throws {
        let pages = textSize == .ax5 ? 4 : 2
        try audit(app, screen, textSize)
        for page in 2...pages {
            app.swipeUp()
            settle()
            try audit(app, "\(screen), page \(page)", textSize)
        }
        for _ in 2...pages {
            app.swipeDown()
        }
    }

    /// Audits the screen on display. Issues are skipped only by the named
    /// rules in `shouldSkip`, never all of one kind.
    @MainActor
    private func audit(_ app: XCUIApplication, _ screen: String, _ textSize: TextSize) throws {
        // Dynamic Type is audited at AX5, where the text is large: at the
        // default size the check reports SwiftUI text that the AX5 run shows
        // growing without clipping.
        let types: XCUIAccessibilityAuditType = textSize == .ax5 ? .all : XCUIAccessibilityAuditType.all.subtracting(.dynamicType)
        try XCTContext.runActivity(named: "Accessibility audit: \(screen)") { activity in
            var reported = false
            try Self.retryingTimeout { try app.performAccessibilityAudit(for: types) { issue in
                let skip = Self.shouldSkip(issue, in: app)
                let element = issue.element.map { "\($0.elementType) “\($0.label)” at \($0.frame)" } ?? "no element"
                XCTContext.runActivity(named: "\(skip.map { "Skipped (\($0))" } ?? "Reported"): \(issue.compactDescription) — \(element) — \(issue.detailedDescription)") { _ in }
                reported = reported || skip == nil
                return skip != nil
            } }
            // The screen as the audit saw it, to read a failure from CI.
            if reported {
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = screen
                screenshot.lifetime = .keepAlways
                activity.add(screenshot)
            }
        }
    }

    /// The audit gives up on a busy machine ("Audit failed to complete in
    /// time", code -56); one more try, then the error stands.
    @MainActor
    private static func retryingTimeout(_ run: () throws -> Void) throws {
        do {
            try run()
        } catch let error as NSError where error.domain == "com.apple.xcode.xctest.accessibilityAudit" && error.code == -56 {
            try run()
        }
    }

    /// Lets a swipe's scroll come to rest before the audit reads the screen.
    private func settle() {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Scroll settles")], timeout: 1)
    }

    /// Text the AX5 audit calls "partially unsupported" that was seen growing
    /// at AX5, with how it was measured.
    private static let knownDynamicTypeFalsePositives = [
        // Settings' section header: 145 pt tall over three lines at AX5.
        "My subscriptions": "Form section header, 145 pt at AX5",
    ]

    /// Why an issue isn't the app's to fix, or `nil` to report it.
    @MainActor
    private static func shouldSkip(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication) -> String? {
        guard let element = issue.element else {
            // The audit reaches nodes hidden from VoiceOver too, and can't
            // name them. StreamIn hides only decoration whose meaning a
            // neighbour already says: flags beside country names, the TMDB
            // logo above its sentence, the picker's check mark (the row is
            // "selected"), posters and the globe.
            return [.contrast, .textClipped].contains(issue.auditType) ? "hidden from VoiceOver" : nil
        }
        // Flags and the verdict emoji: color glyphs have no single text color
        // to contrast, draw beyond their line box, and the slot reels size
        // theirs to the reel (hidden from VoiceOver).
        if element.label.isEmojiOnly,
           [.contrast, .textClipped, .dynamicType].contains(issue.auditType) {
            return "emoji"
        }
        // Bar buttons are the system's Liquid Glass: it draws them and caps
        // their text size.
        if [.contrast, .dynamicType].contains(issue.auditType),
           !element.label.isEmpty,
           app.navigationBars.buttons[element.label].exists {
            return "system bar button"
        }
        // The audit's contrast check samples blended pixels; WCAG AA on the
        // element's own pixels is the requirement. Single runs of text only:
        // a row combined into one element always holds a white title, which
        // would hide a dim line beside it.
        if issue.auditType == .contrast,
           element.elementType == .staticText,
           let ratio = WCAGContrast.ratio(in: element.screenshot().image),
           ratio >= WCAGContrast.minimum {
            return "WCAG \(ratio.formatted(.number.precision(.fractionLength(1)))):1"
        }
        // A text field scrolls its text sideways rather than clip it.
        if issue.auditType == .textClipped,
           [.textField, .searchField].contains(element.elementType) {
            return "text field"
        }
        // Text, or the list row holding it, partly scrolled out of view: the
        // audit can't see all of it. Long screens are audited again scrolled.
        let screen = app.windows.firstMatch.frame
        if [.contrast, .textClipped, .dynamicType].contains(issue.auditType),
           !screen.contains(element.frame) || app.cells.allElementsBoundByIndex.contains(where: {
               $0.frame.contains(element.frame) && !screen.contains($0.frame)
           }) {
            return "partly off screen"
        }
        // Measured false positives, by name, so new fixed-size text still fails.
        if issue.auditType == .dynamicType,
           let reason = Self.knownDynamicTypeFalsePositives[element.label] {
            return reason
        }
        return nil
    }
}

private extension String {
    /// Flags, 🍿, 📖: every character is a color glyph.
    var isEmojiOnly: Bool {
        !isEmpty && allSatisfy { character in
            character.isWhitespace || character.unicodeScalars.contains {
                $0.properties.isEmojiPresentation || Self.regionalIndicators.contains($0.value)
            }
        }
    }

    /// The letters a flag is made of.
    static let regionalIndicators: ClosedRange<UInt32> = 0x1F1E6...0x1F1FF
}
