import CairnCore
import SwiftUI

struct VocabularyScreen: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    let currentPage: Int
    let pageCount: Int

    @State private var selected: MomentCategory = .heaviness

    private let columns = [
        GridItem(.flexible(), spacing: CairnSpacing.size3),
        GridItem(.flexible(), spacing: CairnSpacing.size3),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.cairnPaper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: CairnSpacing.size3) {
                Text("Notice what’s here")
                    .font(.cairnEyebrow)
                    .tracking(CairnTracking.eyebrowCaps)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .textCase(.uppercase)
                    .padding(.top, CairnSpacing.size6)
                Text("No moment is good or bad. It just *is*. Tap any stone to see what it holds.")
                    .font(.cairnBody)
                    .foregroundStyle(Color.cairnTextSecondary)
                    .lineSpacing(2)
                    .padding(.bottom, CairnSpacing.size3)

                LazyVGrid(columns: columns, spacing: CairnSpacing.size4) {
                    ForEach(MomentCategory.allCases, id: \.self) { category in
                        MomentChip(
                            category: category,
                            size: .medium,
                            isSelected: selected == category
                        ) {
                            withAnimation(.easeOut(duration: 0.22)) {
                                selected = category
                            }
                        }
                    }
                }
                .onboardingEntrance(delay: 0.05)

                glossPanel
                    .id(selected) // forces crossfade on selection change
                    .transition(.opacity)

                Spacer(minLength: 0)

                PageDots(current: currentPage, total: pageCount)
                Button("Next", action: onNext)
                    .buttonStyle(CairnButtonStyle(.primary, size: .large, block: true))
                    .padding(.bottom, CairnSpacing.size6)
            }
            .padding(.horizontal, CairnSpacing.gutter)

            SkipButton(action: onSkip)
        }
    }

    private var glossPanel: some View {
        HStack(spacing: CairnSpacing.size3) {
            CategoryDot(category: selected, size: 36, showsGlyph: true, filled: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(selected.displayName)
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text(gloss(for: selected))
                    .font(.cairnBody)
                    .foregroundStyle(Color.cairnTextSecondary)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, CairnSpacing.size3)
        .padding(.horizontal, CairnSpacing.size3)
        .background(Color.cairnSurfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: CairnRadii.medium)
                .strokeBorder(Color.cairnBorderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
    }

    /// Onboarding-specific glosses — fuller than `MomentCategory.summary`, used only here.
    /// Lifted verbatim from the design system's `GLOSS` map.
    private func gloss(for category: MomentCategory) -> String {
        switch category {
        case .contentment:
            "A settled, easy presence. When things feel quietly right."
        case .desire:
            "Craving or wanting. The pull toward something you don’t have."
        case .aversion:
            "Pushing away. Irritation, resistance, not-wanting."
        case .restlessness:
            "Keyed up and scattered. Hard to settle, hard to focus."
        case .heaviness:
            "Dull and weighed down. When everything feels like effort."
        case .doubt:
            "Uncertain and wavering. Second-guessing, unsure which way to move."
        }
    }
}

#Preview {
    VocabularyScreen(onNext: {}, onSkip: {}, currentPage: 2, pageCount: 4)
}
