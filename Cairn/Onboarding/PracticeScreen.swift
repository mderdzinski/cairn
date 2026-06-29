import CairnCore
import SwiftUI

struct PracticeScreen: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.cairnPaper.ignoresSafeArea()
            litStoneBackdrop

            VStack(spacing: CairnSpacing.size8) {
                Spacer()
                StoneStack(count: 6, size: .large)
                    .onboardingEntrance(duration: 0.5)
                VStack(spacing: CairnSpacing.size3) {
                    Text("A quiet practice of noticing.")
                        .font(.cairnSerif(size: 30, weight: .light))
                        .tracking(CairnTracking.displayTight)
                        .foregroundStyle(Color.cairnTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    Text("Notice a moment. Mark it in a second. Return to it when you’re ready.")
                        .font(.cairnBody)
                        .foregroundStyle(Color.cairnTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 280)
                }
                .padding(.horizontal, CairnSpacing.gutter)
                .onboardingEntrance(delay: 0.2)
                Spacer()
                PageDots(current: currentPage, total: pageCount)
                Button("Next", action: onNext)
                    .buttonStyle(CairnButtonStyle(.primary, size: .large, block: true))
                    .padding(.horizontal, CairnSpacing.gutter)
                    .padding(.bottom, CairnSpacing.size6)
            }

            SkipButton(action: onSkip)
        }
    }

    private var litStoneBackdrop: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    Color.cairnSage100.opacity(0.62),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.5, y: 0.02),
                startRadius: 0,
                endRadius: geo.size.width * 0.7
            )
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

struct PageDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.cairnAccent : Color.cairnBorderStrong)
                    .frame(width: index == current ? 18 : 6, height: 6)
                    .animation(.easeOut(duration: 0.3), value: current)
            }
        }
        .padding(.bottom, CairnSpacing.size2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(current + 1) of \(total)"))
    }
}

#Preview {
    PracticeScreen(onNext: {}, onSkip: {}, currentPage: 1, pageCount: 4)
}
