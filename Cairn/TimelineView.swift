import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.timestamp, order: .reverse)
    private var moments: [Moment]
    @State private var reflectingMoment: Moment?

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
            .sheet(item: $reflectingMoment) { moment in
                ReflectSheet(
                    moment: moment,
                    onDismiss: { reflectingMoment = nil },
                    onDelete: { delete(moment) }
                )
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
                            Button {
                                reflectingMoment = moment
                            } label: {
                                row(for: moment)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.cairnSurfaceCard)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(moment)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
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

    private func delete(_ moment: Moment) {
        if reflectingMoment?.id == moment.id {
            reflectingMoment = nil
        }
        modelContext.delete(moment)
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: Moment.self, inMemory: true)
}
