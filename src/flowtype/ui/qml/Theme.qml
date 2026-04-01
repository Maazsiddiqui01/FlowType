import QtQuick

QtObject {
    readonly property bool darkMode: (typeof AppController !== "undefined" && AppController !== null)
        ? AppController.darkMode : false

    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int space40: 40

    readonly property int shellPadding: 24
    readonly property int pageGap: 24
    readonly property int sectionGap: 24
    readonly property int cardPadding: 20
    readonly property int cardPaddingLarge: 24

    readonly property int controlHeightCompact: 36
    readonly property int controlHeight: 40
    readonly property int buttonHeight: 40
    readonly property int chipHeight: 24
    readonly property int railItemHeight: 42
    readonly property int railWidth: 196

    readonly property int radiusShell: 20
    readonly property int radiusCard: 18
    readonly property int radiusControl: 12
    readonly property int radiusPill: 999

    readonly property color appBackground: darkMode ? "#0B1017" : "#F5F7FA"
    readonly property color surface: darkMode ? "#111723" : "#FFFFFF"
    readonly property color surfaceSubtle: darkMode ? "#0F1520" : "#FAFBFC"
    readonly property color surfaceMuted: darkMode ? "#151D2A" : "#F1F4F8"
    readonly property color surfaceHover: darkMode ? "#182131" : "#EEF3FA"
    readonly property color border: darkMode ? "#222C39" : "#DEE6F0"
    readonly property color divider: darkMode ? "#1A2330" : "#E8EEF5"
    readonly property color borderSelected: darkMode ? "#53677F" : "#B7C6DA"

    readonly property color textPrimary: darkMode ? "#F5F7FB" : "#14324A"
    readonly property color textSecondary: darkMode ? "#98A8BC" : "#607588"
    readonly property color textTertiary: darkMode ? "#6F8197" : "#8A99AA"

    readonly property color primary: darkMode ? "#6A82FF" : "#2F6BFF"
    readonly property color teal: darkMode ? "#38BFA7" : "#139B93"
    readonly property color warm: darkMode ? "#F2B84B" : "#E39C24"
    readonly property color error: darkMode ? "#F07474" : "#DF5B52"
    readonly property color success: darkMode ? "#37C7A2" : "#139B93"

    readonly property color glassHighlight: darkMode ? Qt.rgba(1, 1, 1, 0.02) : Qt.rgba(1, 1, 1, 0.68)
    readonly property color accentGlow: darkMode ? Qt.rgba(0.42, 0.51, 1.0, 0.08) : Qt.rgba(0.18, 0.42, 1.0, 0.05)

    readonly property string fontDisplay: "Segoe UI Variable Display"
    readonly property string fontText: "Segoe UI Variable Text"
    readonly property string fontUi: "Segoe UI Variable Text"
    readonly property string fontMono: "Cascadia Code"

    readonly property int sizeAppTitle: 22
    readonly property int sizePageTitle: 20
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

    function tint(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
}
