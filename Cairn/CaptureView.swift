import CairnCore
import SwiftData
import SwiftUI
import UIKit

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Moment.timestamp, order: .reverse) private var allMoments: [Moment]

    private var todaysMomentCount: Int {
        allMoments.filter { Calendar.current.isDateInToday($0.timestamp) }.count
    }

    private let columns = [
        GridItem(.flexible(), spacing: CairnSpacing.size3),
        GridItem(.flexible(), spacing: CairnSpacing.size3),
        GridItem(.flexible(), spacing: CairnSpacing.size3),
    ]

    var body: some View {
        ZStack {
            Color.cairnPaper.ignoresSafeArea()
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size2) {
            Text(eyebrowDate)
                .font(.cairnEyebrow)
                .tracking(CairnTracking.eyebrowCaps)
                .foregroundStyle(Color.cairnTextTertiary)
                .textCase(.uppercase)
            Text("How is it,\nright now?")
                .font(.cairnDisplay)
                .tracking(CairnTracking.displayTight)
                .foregroundStyle(Color.cairnTextPrimary)
                .lineSpacing(-4)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: CairnSpacing.size6) {
            ForEach(MomentCategory.allCases, id: \.self) { category in
                MomentChip(category: category) {
                    capture(category)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: CairnSpacing.size3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stoneCountLine)
                    .font(.cairnLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.cairnTextPrimary)
                Text("Reflect on them this evening.")
                    .font(.cairnBody)
                    .foregroundStyle(Color.cairnTextSecondary)
            }
            Spacer()
        }
        .padding(CairnSpacing.size4)
        .background(Color.cairnBgSunken)
        .clipShape(RoundedRectangle(cornerRadius: CairnRadii.card))
    }

    private var eyebrowDate: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.wide))
        let monthDay = Date.now.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)"
    }

    private var stoneCountLine: String {
        let count = todaysMomentCount
        return "\(count) \(count == 1 ? "stone" : "stones") today"
    }

    private func capture(_ category: MomentCategory) {
        let moment = Moment(category: category)
        modelContext.insert(moment)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: Moment.self, inMemory: true)
}
