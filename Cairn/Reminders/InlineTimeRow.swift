import CairnCore
import SwiftUI

struct InlineTimeRow: View {
    let label: String
    @Binding var minutes: Int
    @Binding var isExpanded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var date: Binding<Date> {
        Binding(
            get: { Self.date(from: minutes) },
            set: { minutes = Self.minutes(from: $0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                MotionGate.animate(reduceMotion: reduceMotion, .easeOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: CairnSpacing.size2) {
                    Text(label)
                        .font(.cairnLabel.weight(.medium))
                        .foregroundStyle(Color.cairnTextPrimary)
                    Spacer(minLength: 0)
                    Text(RemindersSettings.format(minutes: minutes))
                        .font(.cairnMono)
                        .foregroundStyle(isExpanded ? Color.cairnAccentInk : Color.cairnTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.cairnTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, CairnSpacing.size3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .colorScheme(.light)
                    .motionAwareTransition(
                        .opacity.combined(with: .move(edge: .top)),
                        reduceMotion: reduceMotion
                    )
            }
        }
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
