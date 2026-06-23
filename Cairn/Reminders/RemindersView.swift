import CairnCore
import SwiftData
import SwiftUI

private enum ActiveSheet: Identifiable {
    case activeHours
    case reflectTime

    var id: Int {
        switch self {
        case .activeHours: 0
        case .reflectTime: 1
        }
    }
}

struct RemindersView: View {
    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())
    @Environment(RemindersService.self) private var remindersService
    @Query private var moments: [Moment]
    @State private var activeSheet: ActiveSheet?

    private var settings: Binding<RemindersSettings> {
        Binding(
            get: { RemindersSettings.decode(settingsData) },
            set: { settingsData = RemindersSettings.encode($0) }
        )
    }

    private var pendingCount: Int {
        moments.lazy.filter {
            ($0.reflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: CairnSpacing.size4) {
                    intro
                    noticeCard
                    reflectCard
                }
                .padding(.horizontal, CairnSpacing.gutter)
                .padding(.top, CairnSpacing.size3)
                .padding(.bottom, CairnSpacing.size10)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Reminders")
                    .font(.cairnTitle)
                    .foregroundStyle(Color.cairnTextPrimary)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            timePicker(for: sheet)
        }
        .onChange(of: settingsData) { _, newValue in
            let decoded = RemindersSettings.decode(newValue)
            Task { await remindersService.reschedule(settings: decoded) }
        }
    }

    private var intro: some View {
        Text("Cairn can gently remind you to notice — and to revisit what's waiting. Both are off until you ask.")
            .font(.cairnSerif(size: 17, weight: .regular))
            .foregroundStyle(Color.cairnTextSecondary)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            ReminderCardHead(
                systemImage: "bell",
                title: "Notice reminders",
                subtitle: "A nudge at a random moment to pause and notice",
                isOn: settings.noticeEnabled
            )
            if settings.wrappedValue.noticeEnabled {
                Divider().background(Color.cairnBorderSubtle)
                ValueRow(
                    label: "Active hours",
                    value: activeHoursValue
                ) {
                    activeSheet = .activeHours
                }
                Text("Reminders only arrive inside this window — never while you're asleep.")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .lineSpacing(1)
                Divider().background(Color.cairnBorderSubtle)
                frequencyPicker
                NotifPreview(
                    bodyText: "What are you noticing right now?",
                    action: openCapture
                )
            }
        }
        .cairnCard()
    }

    private var reflectCard: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            ReminderCardHead(
                systemImage: "pencil",
                title: "Reflection reminders",
                subtitle: "A daily check-in when moments are waiting",
                isOn: settings.reflectEnabled
            )
            if settings.wrappedValue.reflectEnabled {
                Divider().background(Color.cairnBorderSubtle)
                ValueRow(
                    label: "Remind me at",
                    value: RemindersSettings.format(minutes: settings.wrappedValue.reflectTime)
                ) {
                    activeSheet = .reflectTime
                }
                Text(reflectHelperText)
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .lineSpacing(1)
                NotifPreview(
                    bodyText: reflectPreviewBody,
                    action: openPath
                )
            }
        }
        .cairnCard()
    }

    private var frequencyPicker: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size2) {
            Text("How often")
                .font(.cairnLabel.weight(.medium))
                .foregroundStyle(Color.cairnTextPrimary)
            HStack(spacing: CairnSpacing.size2) {
                ForEach(RemindersSettings.Frequency.allCases, id: \.self) { freq in
                    CairnTag(
                        freq.displayName,
                        isSelected: settings.wrappedValue.freq == freq,
                        isSelectable: true
                    ) {
                        settings.wrappedValue.freq = freq
                    }
                }
            }
            Text(frequencyHelperText)
                .font(.cairnLabel)
                .foregroundStyle(Color.cairnTextTertiary)
                .lineSpacing(1)
        }
    }

    private var activeHoursValue: String {
        let start = RemindersSettings.format(minutes: settings.wrappedValue.activeHoursStart)
        let end = RemindersSettings.format(minutes: settings.wrappedValue.activeHoursEnd)
        return "\(start) – \(end)"
    }

    private var frequencyHelperText: String {
        switch settings.wrappedValue.freq {
        case .once: "One reminder at a random time each day."
        case .few: "Two or three a day, spaced at least an hour apart."
        }
    }

    private var reflectHelperText: String {
        let base = "Sent only when moments are waiting"
        if pendingCount > 0 {
            return base + " — \(pendingCount) right now. If there's nothing to revisit, no reminder."
        }
        return base + ". If there's nothing to revisit, no reminder."
    }

    private var reflectPreviewBody: String {
        let count = max(pendingCount, 3)
        return "\(count) moments are waiting to be revisited."
    }

    @ViewBuilder
    private func timePicker(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .activeHours:
            TimePickerSheet(
                title: "Active hours",
                startMinutes: settings.activeHoursStart,
                endMinutes: Binding(
                    get: { settings.wrappedValue.activeHoursEnd },
                    set: { settings.wrappedValue.activeHoursEnd = $0 ?? settings.wrappedValue.activeHoursEnd }
                ),
                onDone: { activeSheet = nil }
            )
        case .reflectTime:
            TimePickerSheet(
                title: "Remind me at",
                startMinutes: settings.reflectTime,
                onDone: { activeSheet = nil }
            )
        }
    }

    private func openCapture() {
        if let url = URL(string: "cairn://capture") {
            UIApplication.shared.open(url)
        }
    }

    private func openPath() {
        if let url = URL(string: "cairn://path") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        RemindersView()
            .modelContainer(for: Moment.self, inMemory: true)
            .environment(RemindersService())
    }
}
