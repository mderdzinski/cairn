import SwiftUI

/// Runs an action on every scene activation and calendar-day change — the two
/// signals that together cover a midnight crossed while the app is resident
/// (`NSCalendarDayChanged`) and one crossed while it was suspended (the
/// day-changed notification isn't delivered then, but the foreground activation
/// is). Views that bake "today" into fetch descriptors or section titles use
/// this to re-derive their day anchor; see `TodayMomentsReader` for the query
/// half of the pattern.
public struct DayRolloverModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let action: () -> Void

    public func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { action() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                action()
            }
    }
}

public extension View {
    func refreshOnDayRollover(perform action: @escaping () -> Void) -> some View {
        modifier(DayRolloverModifier(action: action))
    }
}
