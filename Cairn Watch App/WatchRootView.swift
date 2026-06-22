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
    @Query(sort: \Moment.timestamp, order: .reverse) private var allMoments: [Moment]
    @State private var screen: WatchScreen = .home
    @State private var dismissTask: Task<Void, Never>?

    private var todaysMomentCount: Int {
        allMoments.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    var body: some View {
        Group {
            switch screen {
            case .home:
                WatchHomeView(todayCount: todaysMomentCount) {
                    withAnimation(.easeInOut(duration: 0.2)) { screen = .capture }
                }
            case .capture:
                WatchCaptureView(
                    onCapture: handleCapture,
                    onClose: { withAnimation { screen = .home } }
                )
            case .confirm(let category):
                WatchConfirmView(category: category)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screen)
    }

    private func handleCapture(_ category: MomentCategory) {
        modelContext.insert(Moment(category: category))
        WKInterfaceDevice.current().play(.click)
        withAnimation { screen = .confirm(category) }
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            withAnimation { screen = .home }
        }
    }
}
