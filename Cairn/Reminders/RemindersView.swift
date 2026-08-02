import CairnCore
import SwiftData
import SwiftUI

private enum PendingToggle {
    case notice
    case reflect
}

private enum ExpandedRow: Hashable {
    case activeStart
    case activeEnd
    case reflectTime
}

struct RemindersView: View {
    let onPreviewTap: (CairnTab) -> Void

    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())
    @Environment(RemindersService.self) private var remindersService
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @State private var expandedRow: ExpandedRow?
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

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: CairnSpacing.size4) {
                    intro
                    if remindersService.currentAuthorizationStatus == .denied {
                        permissionDeniedBanner
                    }
                    if remindersService.lastScheduleFailure != nil {
                        scheduleFailureBanner
                    }
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
        .sheet(isPresented: $isPriming) {
            PrimingSheet(
                onAllow: { Task { await primingAllowed() } },
                onDismiss: dismissPriming
            )
        }
        .onChange(of: settingsData) { _, newValue in
            let decoded = RemindersSettings.decode(newValue)
            Task {
                await remindersService.reschedule(
                    settings: decoded,
                    waitingMomentTimestamp: MomentTimelineFetcher.newestWaitingMomentTimestamp(in: modelContext)
                )
            }
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
        Text("Gentle reminders to notice, and to revisit what's waiting.")
            .font(.cairnSerif(size: 17, weight: .regular))
            .foregroundStyle(Color.cairnTextSecondary)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionDeniedBanner: some View {
        HStack(alignment: .top, spacing: CairnSpacing.size2) {
            Image(systemName: "bell.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cairnStone600)
                .padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CairnSpacing.size1) {
                Text("Notifications are off in iOS Settings")
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text("Cairn can't send reminders until notifications are allowed in iOS Settings.")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.cairnLabel.weight(.medium))
                .foregroundStyle(Color.cairnAccentInk)
                .padding(.top, CairnSpacing.size1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, CairnSpacing.size3)
        .padding(.horizontal, CairnSpacing.size3)
        .background(Color.cairnStone100)
        .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
    }

    private var scheduleFailureBanner: some View {
        HStack(alignment: .top, spacing: CairnSpacing.size2) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cairnStone600)
                .padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CairnSpacing.size1) {
                Text("Reminders couldn't be scheduled")
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text("iOS rejected one or more reminder requests. Try again, or check Notification settings.")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") {
                    let decoded = RemindersSettings.decode(settingsData)
                    Task {
                        await remindersService.reschedule(
                            settings: decoded,
                            waitingMomentTimestamp: MomentTimelineFetcher.newestWaitingMomentTimestamp(in: modelContext)
                        )
                    }
                }
                .font(.cairnLabel.weight(.medium))
                .foregroundStyle(Color.cairnAccentInk)
                .padding(.top, CairnSpacing.size1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, CairnSpacing.size3)
        .padding(.horizontal, CairnSpacing.size3)
        .background(Color.cairnStone100)
        .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
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
                InlineTimeRow(
                    label: "Start",
                    minutes: activeStartBinding,
                    isExpanded: expandedBinding(for: .activeStart)
                )
                InlineTimeRow(
                    label: "End",
                    minutes: activeEndBinding,
                    isExpanded: expandedBinding(for: .activeEnd)
                )
                Text("Reminders only arrive inside this window.")
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
                subtitle: "A nudge to reflect when moments are waiting",
                isOn: toggleBinding(for: .reflect)
            )
            if settings.wrappedValue.reflectEnabled {
                Divider().background(Color.cairnBorderSubtle)
                InlineTimeRow(
                    label: "Remind me at",
                    minutes: settings.reflectTime,
                    isExpanded: expandedBinding(for: .reflectTime)
                )
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

    private var frequencyHelperText: String {
        switch settings.wrappedValue.freq {
        case .once: "One reminder at a random time each day."
        case .few: "Two or three a day, spaced at least an hour apart."
        }
    }

    private var reflectHelperText: String {
        "Arrives at your chosen time, only when recent moments are waiting."
    }

    private var reflectPreviewBody: String {
        "A quiet moment to revisit your path."
    }

    private var activeStartBinding: Binding<Int> {
        Binding(
            get: { settings.wrappedValue.activeHoursStart },
            set: { newStart in
                var current = settings.wrappedValue
                let (clampedStart, clampedEnd) = TimeRangeClamp.enforce(
                    start: newStart,
                    end: current.activeHoursEnd,
                    previousStart: current.activeHoursStart,
                    previousEnd: current.activeHoursEnd
                )
                current.activeHoursStart = clampedStart
                current.activeHoursEnd = clampedEnd
                settings.wrappedValue = current
            }
        )
    }

    private var activeEndBinding: Binding<Int> {
        Binding(
            get: { settings.wrappedValue.activeHoursEnd },
            set: { newEnd in
                var current = settings.wrappedValue
                let (clampedStart, clampedEnd) = TimeRangeClamp.enforce(
                    start: current.activeHoursStart,
                    end: newEnd,
                    previousStart: current.activeHoursStart,
                    previousEnd: current.activeHoursEnd
                )
                current.activeHoursStart = clampedStart
                current.activeHoursEnd = clampedEnd
                settings.wrappedValue = current
            }
        )
    }

    private func expandedBinding(for row: ExpandedRow) -> Binding<Bool> {
        Binding(
            get: { expandedRow == row },
            set: { isOpen in
                MotionGate.animate(reduceMotion: reduceMotion, .easeOut(duration: 0.18)) {
                    expandedRow = isOpen ? row : nil
                }
            }
        )
    }

    private func openCapture() {
        onPreviewTap(.capture)
    }

    private func openPath() {
        onPreviewTap(.path)
    }
}

#Preview("Default") {
    NavigationStack {
        RemindersView()
            .modelContainer(for: Moment.self, inMemory: true)
            .environment(RemindersService())
    }
}

#Preview("Scheduling failure") {
    let service = RemindersService()
    service.lastScheduleFailure = ScheduleFailure(failedCount: 2, totalCount: 3)
    return NavigationStack {
        RemindersView()
            .modelContainer(for: Moment.self, inMemory: true)
            .environment(service)
    }
}
