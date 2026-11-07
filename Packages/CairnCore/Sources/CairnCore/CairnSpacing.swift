import CoreGraphics

public enum CairnSpacing {
    public static let size0: CGFloat = 0
    public static let size1: CGFloat = 4
    public static let size2: CGFloat = 8
    public static let size3: CGFloat = 12
    public static let size4: CGFloat = 16
    public static let size5: CGFloat = 20
    public static let size6: CGFloat = 24
    public static let size8: CGFloat = 32
    public static let size10: CGFloat = 40
    public static let size12: CGFloat = 48
    public static let size16: CGFloat = 64
    public static let size20: CGFloat = 80
    public static let size24: CGFloat = 96

    public static let gutter: CGFloat = 20
    public static let gutterLarge: CGFloat = 32
    public static let touchMin: CGFloat = 44
    public static let watchGutter: CGFloat = 16
}

/// Layout bounds shared by the phone screens. iPhone Duo's inner display (and
/// landscape poses) hand a single-column screen far more width than a phone
/// column was designed for; capping the readable column keeps line lengths and
/// card proportions honest instead of stretching paper edge to edge.
public enum CairnLayout {
    /// Maximum width of a single-column content stack (header + cards + list).
    /// Sits just above the Duo inner display's portrait content width (669pt
    /// minus gutters), so it only bites in landscape and on wider canvases.
    public static let readableWidth: CGFloat = 640
}

public enum CairnRadii {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let card: CGFloat = 18
    public static let extraLarge: CGFloat = 28
    public static let chip: CGFloat = 36
}
