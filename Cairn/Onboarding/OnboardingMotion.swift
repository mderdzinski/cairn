import CairnCore
import SwiftUI

/// Onboarding entrance: 10pt rise + opacity fade over 0.34s with ease-out.
/// When Reduce Motion is on, the view is rendered already-settled with no animation.
/// Pass `delay` for staggered entrances (e.g. headline lands ~0.18s after the stone).
struct OnboardingEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false

    let delay: Double
    let distance: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion || settled ? 1 : 0)
            .offset(y: reduceMotion || settled ? 0 : distance)
            .onAppear {
                guard !reduceMotion else {
                    settled = true
                    return
                }
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    settled = true
                }
            }
    }
}

extension View {
    /// Caps an onboarding column (content or footer) on regular-width displays.
    /// On a phone this never bites; on iPhone Duo's inner display it keeps the
    /// text measure and block buttons at phone proportions, centred, instead
    /// of stretching edge to edge across 669–951pt.
    func onboardingColumn() -> some View {
        frame(maxWidth: CairnLayout.flowColumnWidth)
            .frame(maxWidth: .infinity)
    }

    /// The standard onboarding entrance — 10pt rise + fade, 0.34s ease-out.
    /// Pass a `delay` to stagger multiple elements on the same screen.
    func onboardingEntrance(delay: Double = 0, distance: CGFloat = 10, duration: Double = 0.34) -> some View {
        modifier(OnboardingEntranceModifier(delay: delay, distance: distance, duration: duration))
    }
}
