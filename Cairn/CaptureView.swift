import CairnCore
import os
import SwiftData
import SwiftUI
import UIKit

struct CaptureView: View {
    let onSeePath: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastCaptured: MomentCategory?
    @State private var toastTask: Task<Void, Never>?
    @State private var feedback = UIImpactFeedbackGenerator(style: .medium)

    private let logger = Logger(subsystem: "com.markderdzinski.Cairn", category: "Capture")

    /// The boundary that defines "today" for the stone count. Held in state — not baked
    /// into a query at init — so it can be re-derived when the day rolls over while the
    /// app sits resident in the background. See refreshToday().
    @State private var todayStart = Calendar.current.startOfDay(for: .now)

    init(onSeePath: @escaping () -> Void = {}) {
        self.onSeePath = onSeePath
    }

    private let columns = [
        GridItem(.flexible(), spacing: CairnSpacing.size3),
        GridItem(.flexible(), spacing: CairnSpacing.size3),
    ]

    var body: some View {
        TodayMomentsReader(dayStart: todayStart) { todayCount in
            screen(todayCount: todayCount)
        }
        .onChange(of: scenePhase) { _, phase in
            // Foregrounding after a suspend that crossed midnight won't have delivered
            // NSCalendarDayChanged, so re-derive the boundary on every activation.
            if phase == .active { refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshToday()
        }
    }

    private func screen(todayCount: Int) -> some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()
            sageBackdrop
            // The outer display of iPhone Duo is shorter than any phone this
            // layout was tuned for (678pt tall with the bars on the side), and a
            // fixed-size column of large chips overflowed it, clipping the
            // eyebrow off the top. Offer the column at descending chip sizes and
            // let the first one that fits the available height win; a scrolling
            // column is the floor so nothing is ever unreachable.
            ViewThatFits(in: .vertical) {
                column(todayCount: todayCount, chipSize: .large)
                column(todayCount: todayCount, chipSize: .medium)
                ScrollView {
                    column(todayCount: todayCount, chipSize: .medium)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: CairnLayout.readableWidth)
            .frame(maxWidth: .infinity)

            if let category = lastCaptured {
                MarkedToast(category: category)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    // The safe area already clears the tab bar wherever the
                    // system puts it (bottom on a phone, the side on Duo's outer
                    // display), so only a breathing margin is needed here.
                    .padding(.bottom, CairnSpacing.size4)
                    .motionAwareTransition(
                        .opacity.combined(with: .move(edge: .bottom)),
                        reduceMotion: reduceMotion
                    )
            }
        }
        .task { feedback.prepare() }
    }

    private func column(todayCount: Int, chipSize: ChipSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, CairnSpacing.size2)
            Spacer(minLength: chipSize == .large ? CairnSpacing.size8 : CairnSpacing.size4)
            grid(chipSize: chipSize)
            Spacer(minLength: chipSize == .large ? CairnSpacing.size6 : CairnSpacing.size4)
            footer(todayCount: todayCount)
        }
        .padding(.horizontal, CairnSpacing.gutter)
        .padding(.bottom, CairnSpacing.size6)
    }

    /// Re-derive the start-of-today boundary. Assigning only when it actually changed
    /// keeps this from invalidating the view (and its query) on every activation.
    private func refreshToday() {
        let start = Calendar.current.startOfDay(for: .now)
        if start != todayStart { todayStart = start }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size2) {
            Text(eyebrowDate)
                .font(.cairnEyebrow)
                .tracking(CairnTracking.eyebrowCaps)
                .foregroundStyle(Color.cairnTextTertiary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("What are you\nnoticing?")
                .font(.cairnDisplay)
                .tracking(CairnTracking.displayTight)
                .foregroundStyle(Color.cairnTextPrimary)
                .lineSpacing(-4)
        }
    }

    /// Two columns, always: an even count lets the grid split cleanly at the
    /// fold when Duo is partially open. The chips grow and shrink with the
    /// column; they never stretch into a third column.
    private func grid(chipSize: ChipSize) -> some View {
        LazyVGrid(columns: columns, spacing: CairnSpacing.size3) {
            ForEach(MomentCategory.allCases, id: \.self) { category in
                MomentChip(category: category, size: chipSize) {
                    capture(category)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func footer(todayCount: Int) -> some View {
        Button(action: onSeePath) {
            HStack(spacing: CairnSpacing.size3) {
                StoneStack(count: min(max(todayCount, 1), 6), size: .small)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stoneCountLine(todayCount: todayCount))
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
                    .accessibilityHidden(true)
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

    private func stoneCountLine(todayCount: Int) -> String {
        "\(todayCount) \(todayCount == 1 ? "stone" : "stones") today"
    }

    private func capture(_ category: MomentCategory) {
        feedback.impactOccurred()
        modelContext.insert(Moment(category: category))
        do {
            // Explicit save so a capture is durable at tap time (capture-and-
            // pocket) and CloudKit export to the watch starts immediately,
            // matching the watch app's capture path.
            try modelContext.save()
        } catch {
            logger.error("Failed to save captured moment: \(error.localizedDescription)")
        }

        toastTask?.cancel()
        MotionGate.animate(reduceMotion: reduceMotion, .easeOut(duration: 0.18)) {
            lastCaptured = category
        }
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1300))
            if !Task.isCancelled {
                MotionGate.animate(reduceMotion: reduceMotion, .easeIn(duration: 0.22)) {
                    lastCaptured = nil
                }
            }
        }
        feedback.prepare()
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: Moment.self, inMemory: true)
}
