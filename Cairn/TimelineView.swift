import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Query(sort: \Moment.timestamp, order: .reverse)
    private var moments: [Moment]

    var body: some View {
        NavigationStack {
            Group {
                if moments.isEmpty {
                    ContentUnavailableView(
                        "No moments yet",
                        systemImage: "clock",
                        description: Text("Capture your first moment to see it here.")
                    )
                } else {
                    List {
                        ForEach(groupedDays, id: \.self) { day in
                            Section(sectionTitle(for: day)) {
                                ForEach(grouped[day] ?? []) { moment in
                                    NavigationLink {
                                        MomentDetailView(moment: moment)
                                    } label: {
                                        row(for: moment)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
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
        HStack {
            Text(moment.category.displayName)
            Spacer()
            Text(moment.timestamp.formatted(date: .omitted, time: .shortened))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: Moment.self, inMemory: true)
}
