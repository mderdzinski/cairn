import XCTest

/// Smoke tests for the most load-bearing user paths. Per the MVP polish plan
/// (P6), the goal here is regression insurance for "did the next refactor break
/// capture?", not exhaustive UI coverage. Each test pins behavior the next
/// engineer should be told about if it breaks.
final class CairnUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        // Ensure no prior test's app instance is alive — the simulator can deny
        // launches when the previous XCUIApplication hasn't fully torn down.
        let app = XCUIApplication()
        if app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
    }

    // MARK: - Onboarding gate

    @MainActor
    func testFreshInstallShowsOnboarding() {
        let app = XCUIApplication()
        app.launchArguments += ["-cairn.uitest.reset"]
        app.launch()

        // The cold-open headline is the most reliable text anchor on screen 1.
        let headline = app.staticTexts["Most of what we feel passes unmarked."]
        XCTAssertTrue(
            headline.waitForExistence(timeout: 5),
            "Onboarding cold-open screen should appear when hasSeenOnboarding is unset"
        )
        // Capture tab should NOT be reachable while the cover is up — the
        // .fullScreenCover blocks the underlying TabView from the accessibility tree.
        XCTAssertFalse(
            app.tabBars.buttons["Capture"].isHittable,
            "Tab bar should be inaccessible behind the onboarding cover"
        )
    }

    @MainActor
    func testOnboardingSkippedWhenAlreadySeen() {
        let app = XCUIApplication()
        app.launchArguments += ["-cairn.uitest.seedOnboardingSeen"]
        app.launch()

        // Capture is the default tab — its headline should be visible immediately.
        // SwiftUI splits the multi-line "What are you noticing?" into separate text
        // nodes, so query the prefix.
        let capturePrompt = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'What are you'")
        ).firstMatch
        XCTAssertTrue(
            capturePrompt.waitForExistence(timeout: 5),
            "Capture tab should show immediately when onboarding has been seen"
        )
        // And the onboarding cold-open headline should NOT be present.
        XCTAssertFalse(
            app.staticTexts["Most of what we feel passes unmarked."].exists,
            "Onboarding cover should not appear when hasSeenOnboarding is true"
        )
    }

    // MARK: - Capture → Path

    @MainActor
    func testCaptureLandsInPath() {
        let app = XCUIApplication()
        app.launchArguments += ["-cairn.uitest.seedOnboardingSeen"]
        app.launch()

        // Wait for the tab bar to confirm we're past launch and any onboarding
        // gate. Simulator launches in CI can be slow — generous timeout to avoid
        // flakes when the suite warms up.
        XCTAssertTrue(
            app.tabBars.buttons["Capture"].waitForExistence(timeout: 15),
            "Tab bar should be visible after launch with onboarding seeded"
        )

        // Tap the Contentment chip — every MomentChip has an accessibility label
        // matching its category's displayName.
        let contentmentChip = app.buttons["Contentment"]
        XCTAssertTrue(
            contentmentChip.waitForExistence(timeout: 10),
            "Capture grid should expose category chips by display name"
        )
        contentmentChip.tap()

        // The toast's lifetime is brief (~1.3s) and we don't need to confirm it
        // visually to know the capture landed — Path will show the moment whether
        // or not we observed the toast. Skip straight to verifying persistence.
        app.tabBars.buttons["Path"].tap()

        // The Today section header is the simplest anchor that proves the timeline
        // rendered something — the empty state shows "No moments yet" instead.
        let todayHeader = app.staticTexts["Today"]
        XCTAssertTrue(
            todayHeader.waitForExistence(timeout: 10),
            "Path should show a Today section after a capture"
        )
        XCTAssertFalse(
            app.staticTexts["No moments yet"].exists,
            "Path should not be in its empty state after a capture"
        )
    }
}
