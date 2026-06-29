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
                await remindersService.reschedule(settings: settings)
            }
        }
        .onChange(of: remindersService.lastDeepLinkURL) { _, url in
            guard let url else { return }
            route(url: url)
            remindersService.lastDeepLinkURL = nil
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await reconcileNotificationPermission() }
        }
        .onOpenURL(perform: route(url:))
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
