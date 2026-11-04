//
//  AccessibilityAuditTests.swift
//  StreamInUITests
//
//  Opens each tab and its main screens and runs Xcode's accessibility audit:
//  labels, traits, hit regions. The app reads canned data
//  (`STREAMIN_UI_TEST_FIXTURES=1`, see `FixtureMovieRepository`), so CI needs
//  no TMDB key.
//

import XCTest

final class AccessibilityAuditTests: XCTestCase {

    /// Contrast, clipped text and Dynamic Type are left to the AX5 previews:
    /// in SwiftUI the audit reports emoji and system text there that pass.
    private let auditTypes = XCUIAccessibilityAuditType.all.subtracting([.contrast, .textClipped, .dynamicType])

    @MainActor
    func testEveryTabPassesTheAudit() throws {
        let app = XCUIApplication()
        app.launchEnvironment["STREAMIN_UI_TEST_FIXTURES"] = "1"
        app.launchEnvironment["STREAMIN_IN_MEMORY_WATCHLIST"] = "1"
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-settings.region.code", "ES",
            "-settings.hasCompletedOnboarding", "NO",
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars.buttons["Done"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: auditTypes)
        app.navigationBars.buttons["Done"].tap()

        let searchField = app.textFields["Search a movie"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: auditTypes)

        searchField.tap()
        searchField.typeText("film\n")
        let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Dune'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: auditTypes)

        row.tap()
        XCTAssertTrue(app.buttons["Add to Watchlist"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: auditTypes)

        app.tabBars.buttons["Watchlist"].tap()
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: auditTypes)

        settings.tap()
        XCTAssertTrue(app.navigationBars.buttons["Done"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: auditTypes)
    }
}
