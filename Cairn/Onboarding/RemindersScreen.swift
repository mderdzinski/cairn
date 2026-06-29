import CairnCore
import SwiftUI

struct RemindersScreen: View {
    let onAllow: (_ noticeEnabled: Bool, _ reflectEnabled: Bool) -> Void
    let onDecline: () -> Void

    @State private var noticeOn = true
    @State private var reflectOn = true

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: CairnSpacing.size6) {
                        bellChip
                            .onboardingEntrance()
                        Text("Want Cairn to tap you on the shoulder?")
                            .font(.cairnSerif(size: 28, weight: .light))
                            .tracking(CairnTracking.displayTight)
                            .foregroundStyle(Color.cairnTextPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, CairnSpacing.gutter)
                            .onboardingEntrance(delay: 0.08)
                        VStack(spacing: CairnSpacing.size2) {
                            ReminderPreviewRow(
                                icon: "bell",
                                title: "A nudge to notice",
                                subtitle: "At a random moment in your day",
                                isOn: $noticeOn
                            )
                            ReminderPreviewRow(
                                icon: "pencil",
                                title: "An evening note",
                                subtitle: "Only when moments are waiting",
                                isOn: $reflectOn
                            )
                        }
                        .padding(.horizontal, CairnSpacing.gutter)
                        .onboardingEntrance(delay: 0.16)
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .center)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: CairnSpacing.size2) {
                    Button("Allow reminders") {
                        onAllow(noticeOn, reflectOn)
                    }
                    .buttonStyle(CairnButtonStyle(.primary, size: .large, block: true))
                    Button("I’ll open Cairn myself", action: onDecline)
                        .buttonStyle(CairnButtonStyle(.secondary, size: .large, block: true))
                }
                .padding(.horizontal, CairnSpacing.gutter)
                .padding(.top, CairnSpacing.size3)
                .padding(.bottom, CairnSpacing.size6)
                .background(Color.cairnPaper)
            }
        }
    }

    private var bellChip: some View {
        ZStack {
            Circle()
                .fill(Color.cairnAccentSoft)
                .frame(width: 54, height: 54)
            Image(systemName: "bell")
                .font(.system(size: 25, weight: .regular))
                .foregroundStyle(Color.cairnAccentInk)
        }
        .accessibilityHidden(true)
    }
}

private struct ReminderPreviewRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: CairnSpacing.size3) {
            ZStack {
                Circle()
                    .fill(isOn ? Color.cairnAccentSoft : Color.cairnStone100)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isOn ? Color.cairnAccentInk : Color.cairnTextTertiary)
            }
            .motionAwareAnimation(.easeOut(duration: 0.3), value: isOn, reduceMotion: reduceMotion)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text(subtitle)
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextTertiary)
            }
            Spacer(minLength: 0)
            CairnSwitch(isOn: $isOn, label: title)
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
}

#Preview {
    RemindersScreen(onAllow: { _, _ in }, onDecline: {})
}
