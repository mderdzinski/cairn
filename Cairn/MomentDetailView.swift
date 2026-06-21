import CairnCore
import SwiftData
import SwiftUI

struct MomentDetailView: View {
    @Bindable var moment: Moment

    var body: some View {
        Form {
            Section {
                Text(moment.category.displayName)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(moment.timestamp.formatted(date: .complete, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Reflection") {
                TextField(
                    "What were you thinking?",
                    text: Binding(
                        get: { moment.reflection ?? "" },
                        set: { moment.reflection = $0.isEmpty ? nil : $0 }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MomentDetailView(
            moment: Moment(category: .contentment, reflection: "Sample reflection text.")
        )
    }
    .modelContainer(for: Moment.self, inMemory: true)
}
