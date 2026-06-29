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
    @Query private var todayMoments: [Moment]
    @State private var screen: WatchScreen = .home
    @State private var dismissTask: Task<Void, Never>?

    init() {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp >= startOfDay },
            sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
        )
        _todayMoments = Query(descriptor)
    }

    private var todaysMomentCount: Int {
        todayMoments.count
    }

    var body: some View {
        Group {
            switch screen {
            case .home:
                WatchHomeView(todayCount: todaysMomentCount) {
                    MotionGate.animate(reduceMotion: reduceMotion, .easeInOut(duration: 0.2)) {
                        screen = .capture
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
