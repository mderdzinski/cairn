import CairnCore
import SwiftData
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var justCaptured: MomentCategory?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(MomentCategory.allCases, id: \.self) { category in
                CaptureButton(
                    category: category,
                    isFlashing: justCaptured == category,
                    action: { capture(category) }
                )
            }
        }
        .padding()
    }

    private func capture(_ category: MomentCategory) {
        let moment = Moment(category: category)
        modelContext.insert(moment)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.15)) {
            justCaptured = category
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.2)) {
                justCaptured = nil
            }
        }
    }
}

private struct CaptureButton: View {
    let category: MomentCategory
    let isFlashing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(isFlashing ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: Moment.self, inMemory: true)
}
