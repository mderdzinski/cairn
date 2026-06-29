import CairnCore
import SwiftData
import SwiftUI

struct SettingsView: View {
    let onRoute: (CairnTab) -> Void

    init(onRoute: @escaping (CairnTab) -> Void = { _ in }) {
        self.onRoute = onRoute
    }

    var body: some View {
        NavigationStack {
            RemindersView(onPreviewTap: onRoute)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Moment.self, inMemory: true)
        .environment(RemindersService())
}
