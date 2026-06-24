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

private enum PendingToggle {
    case notice
    case reflect
}

struct RemindersView: View {
    let onPreviewTap: (CairnTab) -> Void

    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())
    @Environment(RemindersService.self) private var remindersService
    @Environment(\.openURL) private var openURL
    @Query private var moments: [Moment]
    @State private var activeSheet: ActiveSheet?
    @State private var pendingToggle: PendingToggle?
    @State private var isPriming = false
    @State private var showsDeniedAlert = false

    init(onPreviewTap: @escaping (CairnTab) -> Void = { _ in }) {
        self.onPreviewTap = onPreviewTap
    }

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
        .sheet(isPresented: $isPriming) {
            PrimingSheet(
                onAllow: { Task { await primingAllowed() } },
                onDismiss: dismissPriming
            )
        }
        .onChange(of: settingsData) { _, newValue in
            let decoded = RemindersSettings.decode(newValue)
            Task { await remindersService.reschedule(settings: decoded) }
        }
        .alert("Notifications are off in Settings", isPresented: $showsDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Cairn can't send reminders until notifications are allowed for Cairn in iOS Settings.")
        }
    }

    private func toggleBinding(for target: PendingToggle) -> Binding<Bool> {
        Binding(
            get: {
                let current = settings.wrappedValue
                return target == .notice ? current.noticeEnabled : current.reflectEnabled
            },
            set: { newValue in
                if newValue {
                    Task { await beginEnable(target: target) }
                    return
                }
                applyToggle(target: target, on: false)
            }
        )
    }

    private func beginEnable(target: PendingToggle) async {
        let status = await remindersService.authorizationStatus()
        switch status {
        case .denied:
            await MainActor.run { showsDeniedAlert = true }
        case .notDetermined:
            await MainActor.run {
                pendingToggle = target
                isPriming = true
            }
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                var current = settings.wrappedValue
                current.hasPrimedPermission = true
                applyToggle(target: target, on: true, into: &current)
                settings.wrappedValue = current
            }
        @unknown default:
            await MainActor.run {
                pendingToggle = target
                isPriming = true
            }
        }
    }

    private func applyToggle(target: PendingToggle, on: Bool) {
        var current = settings.wrappedValue
        applyToggle(target: target, on: on, into: &current)
        settings.wrappedValue = current
    }

    private func applyToggle(target: PendingToggle, on: Bool, into current: inout RemindersSettings) {
        switch target {
        case .notice: current.noticeEnabled = on
        case .reflect: current.reflectEnabled = on
        }
    }

    private func primingAllowed() async {
        let granted = await remindersService.requestAuthorization()
        var current = settings.wrappedValue
        current.hasPrimedPermission = true
        if granted, let target = pendingToggle {
            applyToggle(target: target, on: true, into: &current)
        }
        settings.wrappedValue = current
        await MainActor.run {
            pendingToggle = nil
            isPriming = false
            if !granted {
                showsDeniedAlert = true
            }
        }
    }

    private func dismissPriming() {
        pendingToggle = nil
        isPriming = false
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
                isOn: toggleBinding(for: .notice)
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
                subtitle: "A daily nudge to come back and reflect",
                isOn: toggleBinding(for: .reflect)
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
        if pendingCount > 0 {
            return "A daily nudge at your chosen time — \(pendingCount) waiting to revisit right now."
        }
        return "A daily nudge at your chosen time — a quiet moment to come back to your path."
    }

    private var reflectPreviewBody: String {
        "A quiet moment to revisit your path."
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
        onPreviewTap(.capture)
    }

    private func openPath() {
        onPreviewTap(.path)
    }
}

#Preview {
    NavigationStack {
        RemindersView()
            .modelContainer(for: Moment.self, inMemory: true)
            .environment(RemindersService())
    }
}
