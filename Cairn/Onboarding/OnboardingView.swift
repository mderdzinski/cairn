import CairnCore
import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(RemindersService.self) private var remindersService
    @AppStorage("cairn.hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())

    @State private var step = 0
    @State private var showsDeniedAlert = false
    private let pageCount = 4

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()

            TabView(selection: $step) {
                IntroScreen(onNext: { advance(to: 1) }, onSkip: finish)
                    .tag(0)
                PracticeScreen(
                    onNext: { advance(to: 2) },
                    onSkip: finish,
                    currentPage: 1,
                    pageCount: pageCount
                )
                .tag(1)
                VocabularyScreen(
                    onNext: { advance(to: 3) },
                    onSkip: finish,
                    currentPage: 2,
                    pageCount: pageCount
                )
                .tag(2)
                RemindersScreen(
                    onAllow: { notice, reflect in
                        Task { await allowReminders(notice: notice, reflect: reflect) }
                    },
                    onDecline: finish
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .interactiveDismissDisabled(true)
        .alert("Notifications are off in Settings", isPresented: $showsDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
                finish()
            }
            Button("Cancel", role: .cancel) {
                finish()
            }
        } message: {
            Text("Cairn can't send reminders until notifications are allowed for Cairn in iOS Settings.")
        }
    }

    private func advance(to next: Int) {
        MotionGate.animate(reduceMotion: reduceMotion, .easeOut(duration: 0.3)) {
            step = next
        }
    }

    private func finish() {
        hasSeenOnboarding = true
        dismiss()
    }

    private func allowReminders(notice: Bool, reflect: Bool) async {
        // Permission already denied in iOS Settings: requestAuthorization would
        // return false with no prompt, silently granting nothing the user just
        // asked for. Surface it; finish() moves to the alert's buttons.
        let status = await remindersService.authorizationStatus()
        if status == .denied {
            persistPrimedPermission()
            showsDeniedAlert = true
            return
        }
        let granted = await remindersService.requestAuthorization()
        var settings = RemindersSettings.decode(settingsData)
        // Persisted on both outcomes — a declined prompt still means the user
        // was primed, and iOS won't show the prompt again anyway.
        settings.hasPrimedPermission = true
        if granted {
            settings.noticeEnabled = notice
            settings.reflectEnabled = reflect
        }
        settingsData = RemindersSettings.encode(settings)
        if granted {
            await remindersService.reschedule(
                settings: settings,
                waitingMomentTimestamp: MomentTimelineFetcher.newestWaitingMomentTimestamp(in: modelContext)
            )
        }
        finish()
    }

    private func persistPrimedPermission() {
        var settings = RemindersSettings.decode(settingsData)
        settings.hasPrimedPermission = true
        settingsData = RemindersSettings.encode(settings)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: Moment.self, inMemory: true)
        .environment(RemindersService())
}
