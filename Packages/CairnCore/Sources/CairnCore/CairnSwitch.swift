import SwiftUI

public struct CairnSwitch: View {
    public enum Size {
        case small
        case medium

        var width: CGFloat {
            switch self {
            case .small: 38
            case .medium: 46
            }
        }

        var height: CGFloat {
            switch self {
            case .small: 22
            case .medium: 28
            }
        }

        var inset: CGFloat {
            3
        }

        var knob: CGFloat {
            height - inset * 2
        }

        var travel: CGFloat {
            width - knob - inset * 2
        }
    }

    @Binding public var isOn: Bool
    public let size: Size
    public let label: String?
    public let isDisabled: Bool

    @State private var isPressed = false

    public init(
        isOn: Binding<Bool>,
        size: Size = .medium,
        label: String? = nil,
        isDisabled: Bool = false
    ) {
        _isOn = isOn
        self.size = size
        self.label = label
        self.isDisabled = isDisabled
    }

    public var body: some View {
        Button {
            guard !isDisabled else { return }
            isOn.toggle()
        } label: {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(isOn ? Color.cairnAccent : Color.cairnStone300)
                    .frame(width: size.width, height: size.height)
                Circle()
                    .fill(Color.white)
                    .frame(width: size.knob, height: size.knob)
                    .shadow(
                        color: Color.cairnStone900.opacity(0.22),
                        radius: 1,
                        x: 0,
                        y: 1
                    )
                    .shadow(
                        color: Color.cairnStone900.opacity(0.12),
                        radius: 1,
                        x: 0,
                        y: 1
                    )
                    .scaleEffect(isPressed ? 0.94 : 1.0)
                    .offset(x: size.inset + (isOn ? size.travel : 0))
            }
            .animation(.easeOut(duration: 0.18), value: isOn)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
        .accessibilityLabel(label.map(Text.init) ?? Text(""))
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isOn ? Text("On") : Text("Off"))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}
