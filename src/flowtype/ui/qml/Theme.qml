import QtQuick

QtObject {
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int space40: 40

    readonly property int shellPadding: 16
    readonly property int pageGap: 24
    readonly property int sectionGap: 24
    readonly property int cardPadding: 16
    readonly property int cardPaddingLarge: 24
    readonly property int controlHeightCompact: 36
    readonly property int controlHeight: 40
    readonly property int buttonHeight: 40
    readonly property int chipHeight: 24
    readonly property int railItemHeight: 44
    readonly property int railWidth: 176

    readonly property int radiusShell: 20
    readonly property int radiusCard: 16
    readonly property int radiusControl: 12
    readonly property int radiusPill: 999

    readonly property color appBackground: "#F5F7FA"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceSubtle: "#FAFBFC"
    readonly property color surfaceMuted: "#F1F5F9"
    readonly property color border: "#E2E8F0"
    readonly property color divider: "#EDF2F7"

    readonly property color textPrimary: "#14324A"
    readonly property color textSecondary: "#5F7487"
    readonly property color textTertiary: "#8395A5"

    readonly property color primary: "#2F6BFF"
    readonly property color teal: "#139B93"
    readonly property color warm: "#F59E0B"
    readonly property color error: "#E25C52"
    readonly property color success: "#13A88A"
    readonly property color inkDark: "#07111B"

    readonly property color shadowColor: "#150B20"

    readonly property string fontDisplay: "Segoe UI Variable Display"
    readonly property string fontText: "Segoe UI Variable Text"
    readonly property string fontUi: "Segoe UI Variable Text"
    readonly property string fontMono: "Cascadia Code"

    readonly property int sizeAppTitle: 22
    readonly property int sizePageTitle: 28
    readonly property int sizeSectionTitle: 20
    readonly property int sizeCardTitle: 15
    readonly property int sizeBody: 13
    readonly property int sizeHelper: 12
    readonly property int sizeLabel: 11
    readonly property int sizeMetric: 32
    readonly property int textBody: 13
    readonly property int textHelper: 12
    readonly property int textLabel: 11
    readonly property int textMetric: 32

    function tint(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
}
