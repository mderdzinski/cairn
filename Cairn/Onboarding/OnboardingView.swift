import CairnCore
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RemindersService.self) private var remindersService
    @AppStorage("cairn.hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())

    @State private var step = 0
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
    }

    private func advance(to next: Int) {
        withAnimation(.easeOut(duration: 0.3)) {
            step = next
        }
    }

    private func finish() {
        hasSeenOnboarding = true
        dismiss()
    }

    private func allowReminders(notice: Bool, reflect: Bool) async {
        let granted = await remindersService.requestAuthorization()
        if granted {
            var settings = RemindersSettings.decode(settingsData)
            settings.noticeEnabled = notice
            settings.reflectEnabled = reflect
            settings.hasPrimedPermission = true
            settingsData = RemindersSettings.encode(settings)
            await remindersService.reschedule(settings: settings)
        }
        await MainActor.run { finish() }
    }
}

#Preview {
    OnboardingView()
        .environment(RemindersService())
}
