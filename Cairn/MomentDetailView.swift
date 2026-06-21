import CairnCore
import SwiftData
import SwiftUI

struct MomentDetailView: View {
    @Bindable var moment: Moment

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()
            Form {
                Section {
                    VStack(alignment: .leading, spacing: CairnSpacing.size2) {
                        Text(moment.category.displayName)
                            .font(.cairnDisplay)
                            .tracking(CairnTracking.displayTight)
                            .foregroundStyle(Color.cairnTextPrimary)
                        Text(moment.timestamp.formatted(date: .complete, time: .shortened))
                            .font(.cairnMono)
                            .foregroundStyle(Color.cairnTextSecondary)
                    }
                    .padding(.vertical, CairnSpacing.size1)
                }
                .listRowBackground(Color.cairnSurfaceCard)

                Section {
                    TextField(
                        "Take your time…",
                        text: Binding(
                            get: { moment.reflection ?? "" },
                            set: { moment.reflection = $0.isEmpty ? nil : $0 }
                        ),
                        axis: .vertical
                    )
                    .font(.cairnPrompt)
                    .foregroundStyle(Color.cairnTextPrimary)
                    .lineLimit(3...)
                } header: {
                    Text("Reflection")
                        .font(.cairnEyebrow)
                        .tracking(CairnTracking.eyebrowCaps)
                        .foregroundStyle(Color.cairnTextTertiary)
                        .textCase(.uppercase)
                }
                .listRowBackground(Color.cairnSurfaceCard)
            }
            .scrollContentBackground(.hidden)
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
