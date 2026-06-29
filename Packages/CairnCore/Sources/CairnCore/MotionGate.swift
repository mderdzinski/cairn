import SwiftUI

/// `View` helpers for honoring `accessibilityReduceMotion` on the existing animation
/// primitives without duplicating the `@Environment` plumbing in every call site.
///
/// The pattern across the app: a view reads `@Environment(\.accessibilityReduceMotion)`
/// and uses these helpers in place of bare `withAnimation` / `.animation`. When the
/// user has Reduce Motion on, the state change still applies — it just lands without
/// the easing.
public enum MotionGate {
    /// Wraps `withAnimation` so the state change happens *without* animation when
    /// `reduceMotion` is true. The closure runs in either case.
    public static func animate<Result>(
        reduceMotion: Bool,
        _ animation: Animation,
        _ body: () -> Result
    ) -> Result {
        if reduceMotion {
            var result: Result!
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                result = body()
            }
            return result
        }
        return withAnimation(animation, body)
    }
}

public extension View {
    /// `.animation(_:value:)` that becomes a no-op when Reduce Motion is on. Read
    /// `accessibilityReduceMotion` from `@Environment` and thread it through.
    @ViewBuilder
    func motionAwareAnimation(
        _ animation: Animation,
        value: some Equatable,
        reduceMotion: Bool
    ) -> some View {
        if reduceMotion {
            self.animation(nil, value: value)
        } else {
            self.animation(animation, value: value)
        }
    }

    /// `.transition(_:)` that collapses to `.identity` when Reduce Motion is on.
    @ViewBuilder
    func motionAwareTransition(_ transition: AnyTransition, reduceMotion: Bool) -> some View {
        if reduceMotion {
            self.transition(.identity)
        } else {
            self.transition(transition)
        }
    }
}
