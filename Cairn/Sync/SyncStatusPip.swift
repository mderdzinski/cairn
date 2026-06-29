import CairnCore
import SwiftUI

/// Quiet sync indicator for the Path toolbar. Only renders when there's something
/// the user might want to know — a stone dot + relative time when sync is stale, a
/// sage dot + "Syncing" when in flight, an exclamation glyph + "Sync issue" on
/// failure. Silent when sync is fresh, idle, or disabled — silence is the signal
/// that everything is working.
struct SyncStatusPip: View {
    let status: SyncStatus
    /// When the last successful sync is older than this, the relative time is shown
    /// next to "Synced" instead of just "Synced".
    let staleAfter: TimeInterval

    /// Reads ``Date.now`` once per body render so the relative-time string updates
    /// when the parent invalidates (e.g. on tab switch). The pip is not a live clock.
    private let now: Date

    init(status: SyncStatus, staleAfter: TimeInterval = 5 * 60, now: Date = .now) {
        self.status = status
        self.staleAfter = staleAfter
        self.now = now
    }

    var body: some View {
        switch status {
        case .disabled, .idle:
            EmptyView()
        case .syncing:
            label(dot: .cairnAccent, text: "Syncing", accessible: "Syncing now")
        case .synced(let date):
            if now.timeIntervalSince(date) < staleAfter {
                EmptyView()
            } else {
                label(
                    dot: .cairnStone400,
                    text: "Synced \(relative(from: date))",
                    accessible: "Last synced \(relative(from: date))"
                )
            }
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.cairnStone600)
                Text("Sync issue")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextTertiary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sync issue")
        }
    }

    private func label(dot: Color, text: String, accessible: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dot)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.cairnLabel)
                .foregroundStyle(Color.cairnTextTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessible)
    }

    private func relative(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }
}

#Preview("All states") {
    VStack(alignment: .leading, spacing: 12) {
        SyncStatusPip(status: .syncing)
        SyncStatusPip(status: .synced(since: .now))
        SyncStatusPip(status: .synced(since: Date.now.addingTimeInterval(-15 * 60)))
        SyncStatusPip(status: .failed(since: .now))
        SyncStatusPip(status: .idle)
        SyncStatusPip(status: .disabled)
    }
    .padding(40)
}
