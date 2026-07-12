import SwiftData
import SwiftUI

/// Reads the count of moments logged today and hands it to `content`.
///
/// The query is rebuilt from `dayStart` every time that boundary changes, because a
/// SwiftData `@Query` can only be reconfigured through a view's initializer. Isolating
/// the query here lets a caller keep the "today" boundary in its own `@State` and slide
/// it forward across the midnight rollover — on a long-lived process (notably the watch
/// app, which stays resident past midnight) a boundary captured once at init would keep
/// counting a previous day's moments as today's.
///
/// Callers pass `dayStart` (typically `Calendar.current.startOfDay(for: .now)` held in
/// state) and refresh it on scene activation and on `.NSCalendarDayChanged`.
public struct TodayMomentsReader<Content: View>: View {
    @Query private var todayMoments: [Moment]
    private let content: (Int) -> Content

    public init(dayStart: Date, @ViewBuilder content: @escaping (Int) -> Content) {
        self.content = content
        _todayMoments = Query(MomentTimelineFetcher.todayCountDescriptor(now: dayStart))
    }

    public var body: some View {
        content(todayMoments.count)
    }
}
