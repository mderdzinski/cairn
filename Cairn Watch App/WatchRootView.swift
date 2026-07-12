import CairnCore
import SwiftData
import SwiftUI
import WatchKit

enum WatchScreen: Equatable {
    case home
    case capture
    case confirm(MomentCategory)
}

struct WatchRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var screen: WatchScreen = .home
    @State private var dismissTask: Task<Void, Never>?

    // The boundary that defines "today" for the stone count. Held in state — not baked
    // into a query at init — so it can be re-derived when the day rolls over. The watch
    // app process stays resident across midnight; a fixed init-time cutoff would keep
    // counting a previous day's moments as today's. See refreshToday().
    @State private var todayStart = Calendar.current.startOfDay(for: .now)

    var body: some View {
        Group {
            switch screen {
            case .home:
                TodayMomentsReader(dayStart: todayStart) { todayCount in
                    WatchHomeView(todayCount: todayCount) {
                        MotionGate.animate(reduceMotion: reduceMotion, .easeInOut(duration: 0.2)) {
                            screen = .capture
                        }
                    }
                }
            case .capture:
                WatchCaptureView(
                    onCapture: handleCapture,
                    onClose: {
                        MotionGate.animate(reduceMotion: reduceMotion, .default) {
                            screen = .home
                        }
                    }
                )
            case .confirm(let category):
                WatchConfirmView(category: category)
            }
        }
        .motionAwareAnimation(.easeInOut(duration: 0.25), value: screen, reduceMotion: reduceMotion)
        .onOpenURL(perform: handleDeepLink)
        .onChange(of: scenePhase) { _, phase in
            // Foregrounding after a suspend that crossed midnight won't have delivered
            // NSCalendarDayChanged, so re-derive the boundary on every activation.
            if phase == .active { refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshToday()
        }
    }

    /// Re-derive the start-of-today boundary. Assigning only when it actually changed
    /// keeps this from invalidating the view (and its query) on every activation.
    private func refreshToday() {
        let start = Calendar.current.startOfDay(for: .now)
        if start != todayStart { todayStart = start }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "cairn", url.host == "capture" else { return }
        dismissTask?.cancel()
        MotionGate.animate(reduceMotion: reduceMotion, .easeInOut(duration: 0.2)) {
            screen = .capture
        }
    }

    private func handleCapture(_ category: MomentCategory) {
        WKInterfaceDevice.current().play(.click)
        modelContext.insert(Moment(category: category))
        MotionGate.animate(reduceMotion: reduceMotion, .default) {
            screen = .confirm(category)
        }
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            MotionGate.animate(reduceMotion: reduceMotion, .default) {
                screen = .home
            }
        }
    }
}
