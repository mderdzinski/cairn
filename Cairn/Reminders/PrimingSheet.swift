import CairnCore
import SwiftUI

struct PrimingSheet: View {
    let onAllow: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: CairnSpacing.size4) {
            handle
            bellIcon
            Text("Allow Cairn to remind you?")
                .font(.cairnSerif(size: 24, weight: .light))
                .foregroundStyle(Color.cairnTextPrimary)
                .multilineTextAlignment(.center)
            Text(
                "Cairn sends only the reminders you switch on — a nudge to notice, or to revisit what's waiting. Nothing else, ever."
            )
            .font(.cairnSerif(size: 17, weight: .regular))
            .foregroundStyle(Color.cairnTextSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: 320)
            VStack(spacing: CairnSpacing.size2) {
                Button("Allow notifications") { onAllow() }
                    .buttonStyle(CairnButtonStyle(.primary, block: true))
                Button("Not now") { onDismiss() }
                    .buttonStyle(CairnButtonStyle(.ghost, block: true))
            }
        }
        .padding(.horizontal, CairnSpacing.size5)
        .padding(.top, CairnSpacing.size3)
        .padding(.bottom, CairnSpacing.size8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.cairnSurfaceOverlay)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.cairnBorderStrong)
            .frame(width: 40, height: 5)
            .padding(.top, CairnSpacing.size2)
    }

    private var bellIcon: some View {
        ZStack {
            Circle()
                .fill(Color.cairnAccentSoft)
            Image(systemName: "bell")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Color.cairnAccentInk)
        }
        .frame(width: 60, height: 60)
        .padding(.top, CairnSpacing.size3)
    }
}
