import CairnCore
import SwiftData
import SwiftUI
import UIKit

struct CaptureView: View {
    let onSeePath: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.timestamp, order: .reverse) private var allMoments: [Moment]
    @State private var lastCaptured: MomentCategory?
    @State private var toastTask: Task<Void, Never>?

    init(onSeePath: @escaping () -> Void = {}) {
        self.onSeePath = onSeePath
    }

    private var todaysMomentCount: Int {
        allMoments.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    private let columns = [
        GridItem(.flexible(), spacing: CairnSpacing.size3),
        GridItem(.flexible(), spacing: CairnSpacing.size3),
    ]

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()
            sageBackdrop
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, CairnSpacing.size2)
                Spacer(minLength: CairnSpacing.size8)
                grid
                Spacer(minLength: CairnSpacing.size6)
                footer
            }
            .padding(.horizontal, CairnSpacing.gutter)
            .padding(.bottom, CairnSpacing.size6)

            if let category = lastCaptured {
                MarkedToast(category: category)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 88)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size2) {
            Text(eyebrowDate)
                .font(.cairnEyebrow)
                .tracking(CairnTracking.eyebrowCaps)
                .foregroundStyle(Color.cairnTextTertiary)
                .textCase(.uppercase)
            Text("What are you\nnoticing?")
                .font(.cairnDisplay)
                .tracking(CairnTracking.displayTight)
                .foregroundStyle(Color.cairnTextPrimary)
                .lineSpacing(-4)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: CairnSpacing.size3) {
            ForEach(MomentCategory.allCases, id: \.self) { category in
                MomentChip(category: category, size: .large) {
                    capture(category)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        Button(action: onSeePath) {
            HStack(spacing: CairnSpacing.size3) {
                StoneStack(count: min(max(todaysMomentCount, 1), 6), size: .small)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stoneCountLine)
                        .font(.cairnLabel)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.cairnTextPrimary)
                    Text("Reflect on them this evening")
                        .font(.cairnBody)
                        .foregroundStyle(Color.cairnTextSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.cairnTextTertiary)
            }
            .padding(.vertical, CairnSpacing.size3)
            .padding(.horizontal, CairnSpacing.size4)
            .background(Color.cairnSurfaceCard.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: CairnRadii.card)
                    .strokeBorder(Color.cairnBorderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CairnRadii.card))
            .shadow(color: Color.cairnStone900.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens your path"))
    }

    private var sageBackdrop: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    Color.cairnSage100.opacity(0.55),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.5, y: -0.06),
                startRadius: 0,
                endRadius: geo.size.width * 0.62
            )
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    private var eyebrowDate: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.wide))
        let monthDay = Date.now.formatted(.dateTime.month(.wide).day())
        return "\(weekday) · \(monthDay)"
    }

    private var stoneCountLine: String {
        let count = todaysMomentCount
        return "\(count) \(count == 1 ? "stone" : "stones") today"
    }

    private func capture(_ category: MomentCategory) {
        let moment = Moment(category: category)
        modelContext.insert(moment)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.18)) {
            lastCaptured = category
        }
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1300))
            if !Task.isCancelled {
                withAnimation(.easeIn(duration: 0.22)) {
                    lastCaptured = nil
                }
            }
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: Moment.self, inMemory: true)
}
