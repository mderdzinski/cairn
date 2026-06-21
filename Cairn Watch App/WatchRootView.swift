import CairnCore
import SwiftData
import SwiftUI
import WatchKit

enum WatchScreen: Equatable {
    case face
    case capture
    case confirm(MomentCategory)
}

struct WatchRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.timestamp, order: .reverse) private var allMoments: [Moment]
    @State private var screen: WatchScreen = .face
    @State private var dismissTask: Task<Void, Never>?

    private var todaysMomentCount: Int {
        allMoments.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    var body: some View {
        Group {
            switch screen {
            case .face:
                Text("Cairn")
                    .font(.cairnTitle)
                    .foregroundStyle(Color.cairnTextPrimary)
            case .capture:
                Text("Capture")
                    .font(.cairnTitle)
            case .confirm:
                Text("Confirmed")
                    .font(.cairnTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cairnPaper)
    }

    private func handleCapture(_ category: MomentCategory) {
        modelContext.insert(Moment(category: category))
        WKInterfaceDevice.current().play(.click)
        withAnimation { screen = .confirm(category) }
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            withAnimation { screen = .face }
        }
    }
}
