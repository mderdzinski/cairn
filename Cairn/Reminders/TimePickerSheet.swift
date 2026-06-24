import CairnCore
import SwiftUI

struct TimePickerSheet: View {
    let title: String

    @Binding var startMinutes: Int
    @Binding var endMinutes: Int?

    let onDone: () -> Void

    @State private var startDate: Date
    @State private var endDate: Date

    init(
        title: String,
        startMinutes: Binding<Int>,
        endMinutes: Binding<Int?> = .constant(nil),
        onDone: @escaping () -> Void
    ) {
        self.title = title
        _startMinutes = startMinutes
        _endMinutes = endMinutes
        self.onDone = onDone
        _startDate = State(initialValue: Self.date(from: startMinutes.wrappedValue))
        _endDate = State(initialValue: Self.date(from: endMinutes.wrappedValue ?? 0))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: CairnSpacing.size4) {
                if endMinutes != nil {
                    pickerRow(label: "Start", selection: $startDate)
                    Divider().padding(.horizontal, CairnSpacing.size4)
                    pickerRow(label: "End", selection: $endDate)
                } else {
                    pickerRow(label: "Time", selection: $startDate)
                }
                Spacer()
            }
            .padding(.top, CairnSpacing.size5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commit()
                        onDone()
                    }
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(Color.cairnAccentInk)
                }
            }
            .toolbarBackground(Color.cairnSurfaceOverlay, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.cairnPaper)
        .preferredColorScheme(.light)
    }

    private func pickerRow(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.cairnLabel.weight(.medium))
                .foregroundStyle(Color.cairnTextPrimary)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.horizontal, CairnSpacing.size5)
    }

    private func commit() {
        let newStart = Self.minutes(from: startDate)
        guard endMinutes != nil else {
            startMinutes = newStart
            return
        }
        let newEnd = Self.minutes(from: endDate)
        let (clampedStart, clampedEnd) = Self.enforceMinimumSpan(
            start: newStart,
            end: newEnd,
            previousStart: startMinutes,
            previousEnd: endMinutes ?? newEnd
        )
        startMinutes = clampedStart
        endMinutes = clampedEnd
    }

    /// Returns a (start, end) pair guaranteed to span at least
    /// `minimumSpan` minutes, even at day boundaries (00:00 / 23:59).
    /// When the requested values can't both be honored, the *unedited*
    /// side moves first; if that would push it off the day boundary,
    /// the edited side is pulled back to make room. This means an
    /// invalid commit never silently kills the active-hours window.
    static func enforceMinimumSpan(
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
            // Start was edited: try pushing end forward; if that would
            // overflow the day, pull start back instead.
            let desiredEnd = start + minimumSpan
            if desiredEnd <= dayMax {
                return (start, desiredEnd)
            }
            return (dayMax - minimumSpan, dayMax)
        }
        if endMoved, !startMoved {
            // End was edited: try pulling start back; if that would go
            // below 0, push end forward instead.
            let desiredStart = end - minimumSpan
            if desiredStart >= 0 {
                return (desiredStart, end)
            }
            return (0, minimumSpan)
        }
        // Both moved (or neither moved into a valid arrangement): anchor
        // on start, push end forward, then pull start back if needed.
        let desiredEnd = start + minimumSpan
        if desiredEnd <= dayMax {
            return (start, desiredEnd)
        }
        return (dayMax - minimumSpan, dayMax)
    }

    private static func date(from minutes: Int) -> Date {
        let (hour, minute) = RemindersSettings.hourMinute(from: minutes)
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
