import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Query(sort: \Moment.timestamp, order: .reverse)
    private var moments: [Moment]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cairnPaper.ignoresSafeArea()
                content
            }
            .navigationTitle("Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Path")
                        .font(.cairnTitle)
                        .foregroundStyle(Color.cairnTextPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if moments.isEmpty {
            ContentUnavailableView(
                "No moments yet",
                systemImage: "mountain.2",
                description: Text("Capture your first moment to see it here.")
            )
        } else {
            List {
                ForEach(groupedDays, id: \.self) { day in
                    Section {
                        ForEach(grouped[day] ?? []) { moment in
                            NavigationLink {
                                MomentDetailView(moment: moment)
                            } label: {
                                row(for: moment)
                            }
                            .listRowBackground(Color.cairnSurfaceCard)
                        }
                    } header: {
                        Text(sectionTitle(for: day))
                            .font(.cairnEyebrow)
                            .tracking(CairnTracking.eyebrowCaps)
                            .foregroundStyle(Color.cairnTextTertiary)
                            .textCase(.uppercase)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var grouped: [Date: [Moment]] {
        Dictionary(grouping: moments) { Calendar.current.startOfDay(for: $0.timestamp) }
    }

    private var groupedDays: [Date] {
        grouped.keys.sorted(by: >)
    }

    private func sectionTitle(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    private func row(for moment: Moment) -> some View {
        HStack(spacing: CairnSpacing.size3) {
            CategoryDot(category: moment.category, size: 28)
            Text(moment.category.displayName)
                .font(.cairnBody)
                .foregroundStyle(Color.cairnTextPrimary)
            Spacer()
            Text(moment.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.cairnMono)
                .foregroundStyle(Color.cairnTextSecondary)
        }
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: Moment.self, inMemory: true)
}
