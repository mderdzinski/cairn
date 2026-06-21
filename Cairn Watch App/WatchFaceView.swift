import CairnCore
import Combine
import SwiftUI

struct WatchFaceView: View {
    let todayCount: Int
    let onTapComplication: () -> Void

    @State private var now: Date = .now
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: CairnSpacing.size3) {
            HStack {
                Text(now.formatted(.dateTime.weekday(.abbreviated).day()))
                    .font(.cairnMono(size: 11, weight: .regular))
                    .foregroundStyle(CairnCategoryPalette.ink(.desire))
                Spacer()
                Text(now, format: .dateTime.hour().minute())
                    .font(.cairnMono(size: 11, weight: .regular))
                    .foregroundStyle(Color.cairnAccent)
            }

            Text(now, format: .dateTime.hour().minute())
                .font(.cairnMono(size: 52, weight: .semibold))
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            Button(action: onTapComplication) {
                HStack(spacing: CairnSpacing.size2) {
                    StoneStack(count: max(1, min(todayCount, 6)), size: .small)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(todayCount) today")
                            .font(.cairnLabel.weight(.semibold))
                            .foregroundStyle(Color.cairnTextPrimary)
                        Text("Mark a moment")
                            .font(.cairnLabel)
                            .foregroundStyle(Color.cairnTextSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, CairnSpacing.size3)
                .padding(.vertical, CairnSpacing.size2)
                .background(Color.cairnSurfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
                .shadow(color: Color.cairnStone900.opacity(0.08), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CairnSpacing.size4)
        .padding(.vertical, CairnSpacing.size3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cairnPaper)
        .onReceive(tick) { now = $0 }
    }
}
