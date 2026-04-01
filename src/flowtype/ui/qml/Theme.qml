import QtQuick

QtObject {
    // ── Dark / Light toggle ──────────────────────────────
    readonly property bool darkMode: (typeof AppController !== "undefined" && AppController !== null)
        ? AppController.darkMode : true

    // ── Spacing scale ────────────────────────────────────
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int space40: 40

    readonly property int shellPadding: 20
    readonly property int pageGap: 28
    readonly property int sectionGap: 24
    readonly property int cardPadding: 20
    readonly property int cardPaddingLarge: 28

    readonly property int controlHeightCompact: 36
    readonly property int controlHeight: 42
    readonly property int buttonHeight: 42
    readonly property int chipHeight: 26
    readonly property int railItemHeight: 44
    readonly property int railWidth: 210

    // ── Radii ────────────────────────────────────────────
    readonly property int radiusShell: 16
    readonly property int radiusCard: 16
    readonly property int radiusControl: 10
    readonly property int radiusPill: 999

    // ── Colour palette ───────────────────────────────────
    readonly property color appBackground:  darkMode ? "#0B0D13" : "#F4F6FA"
    readonly property color surface:        darkMode ? "#12161F" : "#FFFFFF"
    readonly property color surfaceSubtle:  darkMode ? "#0F1219" : "#F8F9FC"
    readonly property color surfaceMuted:   darkMode ? "#1A2030" : "#EEF1F6"
    readonly property color surfaceHover:   darkMode ? "#1E2536" : "#F0F3F8"
    readonly property color border:         darkMode ? "#1E293B" : "#E0E5EE"
    readonly property color divider:        darkMode ? "#171D2A" : "#EBF0F5"
    readonly property color borderSelected: darkMode ? "#334155" : "#C0CBE0"

    readonly property color textPrimary:    darkMode ? "#E8ECF2" : "#14324A"
    readonly property color textSecondary:  darkMode ? "#7A8694" : "#5F7487"
    readonly property color textTertiary:   darkMode ? "#4D5A68" : "#8A99AA"

    readonly property color primary:    darkMode ? "#6C8CFF" : "#2F6BFF"
    readonly property color teal:       darkMode ? "#34D399" : "#0FA87A"
    readonly property color warm:       darkMode ? "#FBBF24" : "#E8A317"
    readonly property color error:      darkMode ? "#F87171" : "#E25C52"
    readonly property color success:    darkMode ? "#34D399" : "#0FA87A"
    readonly property color inkDark:    darkMode ? "#060810" : "#07111B"

    readonly property color glassBorder:    darkMode ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color glassHighlight: darkMode ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color accentGlow:     darkMode ? Qt.rgba(0.42, 0.55, 1.0, 0.10) : Qt.rgba(0.18, 0.42, 1.0, 0.06)

    // ── Typography ───────────────────────────────────────
    readonly property string fontDisplay: "Inter"
    readonly property string fontText: "Inter"
    readonly property string fontUi: "Inter"
    readonly property string fontMono: "Cascadia Code"

    readonly property int sizeAppTitle: 20
    readonly property int sizePageTitle: 24
    readonly property int sizeSectionTitle: 16
    readonly property int sizeCardTitle: 14
    readonly property int sizeBody: 13
    readonly property int sizeHelper: 12
    readonly property int sizeLabel: 11
    readonly property int sizeMetric: 30

    // ── Compat aliases ───────────────────────────────────
    readonly property int textBody: 13
    readonly property int textHelper: 12
    readonly property int textLabel: 11
    readonly property int textMetric: 30

    // ── Helpers ──────────────────────────────────────────
    function tint(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
}
