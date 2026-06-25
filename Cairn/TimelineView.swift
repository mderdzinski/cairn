import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.timestamp, order: .reverse)
    private var moments: [Moment]
    @State private var reflectingMoment: Moment?

    private var unreflectedCount: Int {
        moments.lazy.filter { ($0.reflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

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
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, CairnSpacing.gutter)
                    .padding(.top, CairnSpacing.size2)
                if unreflectedCount > 0 {
                    unreflectedBanner
                        .padding(.horizontal, CairnSpacing.gutter)
                        .padding(.top, CairnSpacing.size4)
                }
                list
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: CairnSpacing.size1) {
                Text("Your path")
                    .font(.cairnEyebrow)
                    .tracking(CairnTracking.eyebrowCaps)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .textCase(.uppercase)
                Text("\(moments.count) \(moments.count == 1 ? "moment" : "moments")")
                    .font(.cairnSerif(size: 28, weight: .light))
                    .foregroundStyle(Color.cairnTextPrimary)
            }
            Spacer(minLength: 0)
            StoneStack(count: min(max(moments.count, 1), 6), size: .small)
                .alignmentGuide(.firstTextBaseline) { dim in dim[VerticalAlignment.center] }
        }
    }

    private var unreflectedBanner: some View {
        HStack(spacing: CairnSpacing.size2) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.cairnAccentInk)
            Text("\(unreflectedCount) \(unreflectedCount == 1 ? "moment" : "moments") waiting for reflection")
                .font(.cairnLabel.weight(.medium))
                .foregroundStyle(Color.cairnAccentInk)
            Spacer(minLength: 0)
        }
        .padding(.vertical, CairnSpacing.size3)
        .padding(.horizontal, CairnSpacing.size3)
        .background(Color.cairnSage50)
        .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
    }

    private var list: some View {
        List {
            ForEach(groupedDays, id: \.self) { day in
                Section {
                    ForEach(grouped[day] ?? []) { moment in
                        TimelineEntry(moment: moment) {
                            reflectingMoment = moment
                        }
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

    private var emptyState: some View {
        VStack(spacing: CairnSpacing.size3) {
            Image(systemName: "mountain.2")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.cairnTextTertiary)
            Text("No moments yet")
                .font(.cairnSerif(size: 18, weight: .regular))
                .foregroundStyle(Color.cairnTextPrimary)
            Text("Capture your first moment to see it here.")
                .font(.cairnLabel)
                .foregroundStyle(Color.cairnTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CairnSpacing.size12)
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
