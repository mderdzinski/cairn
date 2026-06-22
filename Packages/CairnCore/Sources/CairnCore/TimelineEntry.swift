import SwiftUI

public struct TimelineEntry: View {
    public let moment: Moment
    public let action: () -> Void

    public init(moment: Moment, action: @escaping () -> Void) {
        self.moment = moment
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: CairnSpacing.size3) {
                CategoryDot(category: moment.category, size: 28)

                VStack(alignment: .leading, spacing: CairnSpacing.size1) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(moment.category.displayName)
                            .font(.cairnBody.weight(.semibold))
                            .foregroundStyle(Color.cairnTextPrimary)
                        Spacer()
                        Text(moment.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.cairnMono)
                            .foregroundStyle(Color.cairnTextTertiary)
                            .monospacedDigit()
                    }

                    if let note = trimmedReflection {
                        Text(note)
                            .font(.cairnSerif(size: 15, weight: .regular))
                            .foregroundStyle(Color.cairnTextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Label {
                            Text("Add a reflection")
                                .font(.cairnLabel.weight(.medium))
                        } icon: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.cairnAccentInk)
                    }
                }
            }
            .padding(.vertical, CairnSpacing.size2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var trimmedReflection: String? {
        guard let raw = moment.reflection else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var accessibilityLabel: Text {
        let time = moment.timestamp.formatted(date: .omitted, time: .shortened)
        return Text("\(moment.category.displayName) at \(time)")
    }

    private var accessibilityHint: Text {
        if trimmedReflection != nil {
            return Text("Has a reflection. Double-tap to view.")
        }
        return Text("No reflection yet. Double-tap to add one.")
    }
}
