import Foundation

enum TimeRangeClamp {
    /// Returns a (start, end) pair guaranteed to span at least
    /// `minimumSpan` minutes, even at day boundaries (00:00 / 23:59).
    /// When the requested values can't both be honored, the *unedited*
    /// side moves first; if that would push it off the day boundary,
    /// the edited side is pulled back to make room. This means an
    /// invalid edit never silently kills the active-hours window.
    static func enforce(
        start: Int,
        end: Int,
        previousStart: Int,
        previousEnd: Int,
        minimumSpan: Int = 60,
        dayMax: Int = 24 * 60 - 1
    ) -> (start: Int, end: Int) {
        if end - start >= minimumSpan {
            return (start, end)
        }
        let startMoved = start != previousStart
        let endMoved = end != previousEnd

        if startMoved, !endMoved {
            let desiredEnd = start + minimumSpan
            if desiredEnd <= dayMax {
                return (start, desiredEnd)
            }
            return (dayMax - minimumSpan, dayMax)
        }
        if endMoved, !startMoved {
            let desiredStart = end - minimumSpan
            if desiredStart >= 0 {
                return (desiredStart, end)
            }
            return (0, minimumSpan)
        }
        let desiredEnd = start + minimumSpan
        if desiredEnd <= dayMax {
            return (start, desiredEnd)
        }
        return (dayMax - minimumSpan, dayMax)
    }
}
