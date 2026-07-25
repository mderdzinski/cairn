import CairnCore
import SwiftData
import SwiftUI

enum CairnTab: Hashable {
    case capture
    case path
    case patterns
    case settings
}

struct RootTabView: View {
    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())
    @AppStorage("cairn.iCloudFallbackBannerDismissed") private var iCloudBannerDismissed = false
    @AppStorage("cairn.hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var selection: CairnTab = .capture
    let remindersService: RemindersService
    let storeBacking: MomentStoreBacking

    init(
        remindersService: RemindersService,
        storeBacking: MomentStoreBacking = .cloud
    ) {
        self.remindersService = remindersService
        self.storeBacking = storeBacking
    }

    private var showsiCloudBanner: Bool {
        storeBacking == .local && !iCloudBannerDismissed
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsiCloudBanner {
                iCloudFallbackBanner
            }
            tabs
        }
        .tint(.cairnAccent)
        .environment(remindersService)
        .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
            OnboardingView()
                .environment(remindersService)
        }
        .task {
            // Capture a launch-time deep link (delivered before view body ran)
            if let url = remindersService.lastDeepLinkURL {
                route(url: url)
                remindersService.lastDeepLinkURL = nil
            }
            await reconcileNotificationPermission()
            let settings = RemindersSettings.decode(settingsData)
            if settings.anyEnabled {
                await remindersService.reschedule(
                    settings: settings,
                    hasWaitingMoments: MomentTimelineFetcher.hasUnreflectedRecentMoments(in: modelContext)
                )
            }
        }
        .task {
            // Reflect fires are gated on moments waiting for reflection, so
            // every data change that could flip that state — a capture, a
            // reflection saved, a delete, or a CloudKit import of a watch
            // capture — needs to recompute the gate. One didSave observer
            // covers all four sources (same liveness pattern as TimelineView).
            for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                await rescheduleIfWaitingChanged()
            }
        }
        .onChange(of: remindersService.lastDeepLinkURL) { _, url in
            guard let url else { return }
            route(url: url)
            remindersService.lastDeepLinkURL = nil
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                // Reconcile first: it may flip the toggles off, and the
                // reschedule below must see that.
                await reconcileNotificationPermission()
                await rescheduleOnForegroundIfNeeded()
            }
        }
        .onOpenURL(perform: route(url:))
    }

    /// Top up the 7-day fire horizon on foreground, at most once per calendar
    /// day. Notices are non-repeating with a bounded look-ahead; without this,
    /// a user whose app is warm-resumed for over a week silently stops
    /// receiving them. Daily (not every-foreground) because each reschedule
    /// re-rolls today's remaining notice times — the scheduler doesn't know
    /// what already fired, so frequent re-rolls risk duplicate same-day fires.
    private func rescheduleOnForegroundIfNeeded() async {
        let settings = RemindersSettings.decode(settingsData)
        guard settings.anyEnabled, authorizedForScheduling else { return }
        await remindersService.rescheduleIfStale(
            settings: settings,
            hasWaitingMoments: MomentTimelineFetcher.hasUnreflectedRecentMoments(in: modelContext)
        )
    }

    /// Reschedule immediately when the "moments waiting for reflection" state
    /// flips — edge-triggered, so ordinary saves cost one fetchCount and only
    /// 0↔positive transitions touch the notification center. Bypasses the
    /// once-per-day gate: a reflection that empties the queue must cancel
    /// pending reflect fires now, not tomorrow. Reflect-scoped, because the
    /// gate only affects reflect fires — a full rebuild here would re-roll
    /// notices right after one fired (capturing in response to a notice is the
    /// primary flow), producing a second same-day notice.
    private func rescheduleIfWaitingChanged() async {
        let settings = RemindersSettings.decode(settingsData)
        guard settings.reflectEnabled, authorizedForScheduling else { return }
        let waiting = MomentTimelineFetcher.hasUnreflectedRecentMoments(in: modelContext)
        guard waiting != remindersService.lastScheduledHasWaiting else { return }
        await remindersService.reschedule(settings: settings, hasWaitingMoments: waiting, scope: .reflectOnly)
    }

    private var authorizedForScheduling: Bool {
        switch remindersService.currentAuthorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    /// On every foreground transition, re-check iOS notification permission. If the
    /// user revoked it in Settings while reminders were enabled, flip the toggles off
    /// and cancel any pending requests so the UI matches reality.
    private func reconcileNotificationPermission() async {
        await remindersService.refreshAuthorizationStatus()
        guard remindersService.currentAuthorizationStatus == .denied else { return }
        var settings = RemindersSettings.decode(settingsData)
        guard settings.anyEnabled else { return }
        settings.noticeEnabled = false
        settings.reflectEnabled = false
        settingsData = RemindersSettings.encode(settings)
        await remindersService.cancelAll()
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            CaptureView(onSeePath: { route(to: .path) })
                .tabItem {
                    Label("Capture", systemImage: "plus")
                }
                .tag(CairnTab.capture)

            TimelineView()
                .tabItem {
                    Label("Path", systemImage: "mountain.2")
                }
                .tag(CairnTab.path)

            PatternsView()
                .tabItem {
                    Label("Patterns", systemImage: "chart.bar")
                }
                .tag(CairnTab.patterns)

            SettingsView(onRoute: route(to:))
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(CairnTab.settings)
        }
    }

    private var iCloudFallbackBanner: some View {
        HStack(spacing: CairnSpacing.size2) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.cairnTextSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sync is paused")
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text("Sign in to iCloud to sync your moments across devices.")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: CairnSpacing.size2)
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.cairnLabel.weight(.medium))
            .foregroundStyle(Color.cairnAccentInk)
            .accessibilityHint("Opens iOS Settings to sign in to iCloud")
            Button {
                iCloudBannerDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.cairnTextTertiary)
                    .padding(CairnSpacing.size1)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(.vertical, CairnSpacing.size3)
        .padding(.horizontal, CairnSpacing.gutter)
        .background(Color.cairnSurfaceOverlay)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.cairnBorderSubtle)
                .frame(height: 0.5)
        }
    }

    private func route(url: URL) {
        guard url.scheme == "cairn", let host = url.host else { return }
        switch host {
        case "capture": route(to: .capture)
        case "path": route(to: .path)
        case "patterns": route(to: .patterns)
        default: break
        }
    }

    private func route(to tab: CairnTab) {
        selection = tab
    }
}

#Preview("Default") {
    RootTabView(remindersService: RemindersService())
        .modelContainer(for: Moment.self, inMemory: true)
        .environment(SyncStatusMonitor(backing: .inMemory))
}

#Preview("iCloud unavailable") {
    RootTabView(remindersService: RemindersService(), storeBacking: .local)
        .modelContainer(for: Moment.self, inMemory: true)
        .environment(SyncStatusMonitor(backing: .local))
}
