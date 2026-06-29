import QtQuick

QtObject {
    id: theme

    readonly property bool darkMode: (typeof AppController !== "undefined" && AppController !== null)
        ? AppController.darkMode : true

    // True when a native translucent material (Mica/Acrylic) is painted behind the
    // window, so surfaces can let it show through. Defaults to false (opaque/solid).
    readonly property bool materialBackdrop: (typeof AppController !== "undefined" && AppController !== null
        && typeof AppController.windowMaterial !== "undefined")
        ? (AppController.windowMaterial !== "solid") : false

    // ── spacing scale ────────────────────────────────────────────────────────
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space10: 10
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int space40: 40

    readonly property int shellPadding: 24
    readonly property int pageGap: 24
    readonly property int sectionGap: 22
    readonly property int cardPadding: 20
    readonly property int cardPaddingLarge: 26

    // ── control sizing ───────────────────────────────────────────────────────
    readonly property int controlHeightCompact: 36
    readonly property int controlHeight: 42
    readonly property int buttonHeight: 42
    readonly property int chipHeight: 26
    readonly property int railItemHeight: 44
    readonly property int railWidth: 212

    // ── radii ────────────────────────────────────────────────────────────────
    readonly property int radiusShell: 22
    readonly property int radiusCard: 18
    readonly property int radiusControl: 12
    readonly property int radiusPill: 999

    // ── backdrop (full window) ───────────────────────────────────────────────
    readonly property color appBackground: darkMode ? "#070B12" : "#EDF1F8"
    readonly property color appGradientTop: darkMode ? "#0C121D" : "#F7FAFE"
    readonly property color appGradientBottom: darkMode ? "#070A11" : "#E7EDF7"

    // ── surfaces (luminance ramp, clearly separated so cards read as layered) ──
    readonly property color surfaceSunken: darkMode ? "#0A0F18" : "#E9EFF7"
    readonly property color surface: darkMode ? "#141C2A" : "#FFFFFF"
    readonly property color surfaceSubtle: darkMode ? "#101722" : "#F6F9FD"
    readonly property color surfaceMuted: darkMode ? "#1A2434" : "#EDF2FA"
    readonly property color surfaceHover: darkMode ? "#202C3F" : "#E8F0FA"
    readonly property color surfaceActive: darkMode ? "#26344B" : "#DEE9F8"

    // Frosted-glass fills: a vertical gradient from a brighter top edge to the base
    // surface, plus a translucent variant for when a native material sits behind.
    readonly property color glassTop: darkMode ? "#1B2638" : "#FFFFFF"
    readonly property color glassBottom: darkMode ? "#121A27" : "#F4F8FD"
    readonly property color glassFillTranslucent: darkMode ? Qt.rgba(0.10, 0.14, 0.21, 0.62) : Qt.rgba(1, 1, 1, 0.66)

    // ── borders & dividers ───────────────────────────────────────────────────
    readonly property color border: darkMode ? "#27344A" : "#D7E1EF"
    readonly property color borderStrong: darkMode ? "#36475F" : "#C2D1E5"
    readonly property color divider: darkMode ? "#1C2735" : "#E5ECF6"
    readonly property color borderSelected: darkMode ? "#5C73A0" : "#A8BEDE"

    // ── text (lifted for WCAG AA on the surface ramp) ────────────────────────
    readonly property color textPrimary: darkMode ? "#F3F6FC" : "#0F2236"
    readonly property color textSecondary: darkMode ? "#ABBAD0" : "#4C6076"
    readonly property color textTertiary: darkMode ? "#8395AE" : "#697E94"

    // ── accents ──────────────────────────────────────────────────────────────
    readonly property color primary: darkMode ? "#6E86FF" : "#2F62F4"
    readonly property color primaryHover: darkMode ? "#7E94FF" : "#3D6FFB"
    readonly property color primaryPressed: darkMode ? "#5C74F0" : "#2752D8"
    readonly property color textOnAccent: "#FFFFFF"
    readonly property color teal: darkMode ? "#3FCBB0" : "#0E988F"
    readonly property color warm: darkMode ? "#F4BC54" : "#D9920F"
    readonly property color error: darkMode ? "#F37A78" : "#D64A47"
    readonly property color success: darkMode ? "#3FCFA6" : "#0E988F"

    // ── glass refraction & glow ──────────────────────────────────────────────
    // Top inner-highlight that sells the "glass edge"; previously 0.02 (invisible).
    readonly property color glassHighlight: darkMode ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.92)
    readonly property color glassLowlight: darkMode ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(0.40, 0.49, 0.62, 0.10)
    readonly property color accentGlow: darkMode ? Qt.rgba(0.43, 0.52, 1.0, 0.16) : Qt.rgba(0.18, 0.42, 1.0, 0.10)

    // ── depth tokens (used for sheen/ramp; no shader effects so cards always paint) ──
    readonly property color shadowColor: darkMode ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0.16, 0.24, 0.40, 0.16)
    readonly property color shadowColorStrong: darkMode ? Qt.rgba(0, 0, 0, 0.72) : Qt.rgba(0.16, 0.24, 0.40, 0.26)
    readonly property real elevation1: 14
    readonly property real elevation2: 26
    readonly property real elevation3: 44
    readonly property real elevationY1: 4
    readonly property real elevationY2: 10
    readonly property real elevationY3: 18

    // ── focus ring (keyboard accessibility) ──────────────────────────────────
    readonly property color focusRing: darkMode ? Qt.rgba(0.55, 0.64, 1.0, 0.85) : Qt.rgba(0.18, 0.38, 0.96, 0.75)
    readonly property int focusRingWidth: 2
    readonly property int focusRingOffset: 3

    // ── HUD (frameless overlay over other apps) ──────────────────────────────
    readonly property color hudFill: darkMode ? Qt.rgba(0.05, 0.07, 0.11, 0.82) : Qt.rgba(0.06, 0.09, 0.14, 0.80)
    readonly property color hudBorder: Qt.rgba(1, 1, 1, 0.10)
    readonly property color hudText: "#F1F5FA"

    // ── typography ───────────────────────────────────────────────────────────
    readonly property string fontDisplay: "Segoe UI Variable Display"
    readonly property string fontText: "Segoe UI Variable Text"
    readonly property string fontUi: "Segoe UI Variable Text"
    readonly property string fontMono: "Cascadia Code"

    readonly property int sizeAppTitle: 22
    readonly property int sizePageTitle: 21
    readonly property int sizeSectionTitle: 16
    readonly property int sizeCardTitle: 14
    readonly property int sizeBody: 13
    readonly property int sizeHelper: 12
    readonly property int sizeLabel: 11
    readonly property int sizeMetric: 30

    readonly property int textBody: sizeBody
    readonly property int textHelper: sizeHelper
    readonly property int textLabel: sizeLabel
    readonly property int textMetric: sizeMetric

    // ── motion tokens ────────────────────────────────────────────────────────
    readonly property int durFast: 110
    readonly property int durBase: 180
    readonly property int durSlow: 280
    readonly property int easeOut: Easing.OutCubic
    readonly property int easeInOut: Easing.InOutQuad
    readonly property int easeEmphasized: Easing.OutBack

    function tint(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    // Mix two colors (ratio 0 -> a, 1 -> b). Handy for state blends.
    function mix(a, b, ratio) {
        return Qt.rgba(
            a.r + (b.r - a.r) * ratio,
            a.g + (b.g - a.g) * ratio,
            a.b + (b.b - a.b) * ratio,
            a.a + (b.a - a.a) * ratio
        )
    }
}
