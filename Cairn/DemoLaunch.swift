import Foundation

/// Launch arguments for producing App Store screenshots and demo recordings.
/// Recognised only when present; every normal launch sees `false` everywhere.
///
/// - `-cairn.demo.seed`: run against an in-memory store seeded with a week of
///   sample moments (the same set the Xcode previews use) and skip onboarding.
/// - `-cairn.demo.reflectNewest`: once Path has loaded, open the newest moment
///   that has no reflection yet, so the reflection sheet (compact) or pane
///   (iPhone Duo open) is on screen without a tap.
///
/// Tabs are reached through the existing `cairn://` deep links
/// (`xcrun simctl openurl <device> cairn://patterns`), so nothing else is needed
/// to drive the app from a script.
enum DemoLaunch {
    static let isSeeded = CommandLine.arguments.contains("-cairn.demo.seed")
    static let reflectsNewest = CommandLine.arguments.contains("-cairn.demo.reflectNewest")
}
