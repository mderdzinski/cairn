import CairnCore
import SwiftUI

struct IntroScreen: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.cairnPaper.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: CairnSpacing.size8) {
                        StoneStack(count: 1, size: .large)
                            .onboardingEntrance(duration: 0.5)
                        Text("Most of what we feel passes unmarked.")
                            .font(.cairnSerif(size: 30, weight: .light))
                            .tracking(CairnTracking.displayTight)
                            .foregroundStyle(Color.cairnTextPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, CairnSpacing.gutter)
                            .onboardingEntrance(delay: 0.18)
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .center)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button("Begin", action: onNext)
                    .buttonStyle(CairnButtonStyle(.primary, size: .large, block: true))
                    .padding(.horizontal, CairnSpacing.gutter)
                    .padding(.top, CairnSpacing.size3)
                    .padding(.bottom, CairnSpacing.size6)
                    .background(Color.cairnPaper)
            }

            SkipButton(action: onSkip)
        }
    }
}

struct SkipButton: View {
    let action: () -> Void

    var body: some View {
        Button("Skip", action: action)
            .font(.cairnLabel.weight(.semibold))
            .foregroundStyle(Color.cairnTextTertiary)
            .padding(.top, CairnSpacing.size3)
            .padding(.trailing, CairnSpacing.gutter)
    }
}

#Preview {
    IntroScreen(onNext: {}, onSkip: {})
}
