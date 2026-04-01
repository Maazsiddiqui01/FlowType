import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property string variant: "secondary"
    property color accent: theme.primary
    property bool compact: false
    property bool buttonEnabled: true

    signal clicked()

    implicitWidth: buttonLabel.implicitWidth + (root.compact ? 26 : 34)
    implicitHeight: root.compact ? theme.controlHeightCompact : theme.buttonHeight
    radius: theme.radiusControl
    opacity: root.buttonEnabled ? 1.0 : 0.48

    color: {
        if (root.variant === "primary")
            return buttonArea.pressed ? Qt.darker(root.accent, 1.08) : (buttonArea.containsMouse ? Qt.lighter(root.accent, 1.04) : root.accent)
        if (root.variant === "danger")
            return buttonArea.pressed ? Qt.darker(theme.error, 1.08) : (buttonArea.containsMouse ? Qt.lighter(theme.error, 1.04) : theme.error)
        if (root.variant === "ghost")
            return buttonArea.containsMouse ? theme.tint(theme.primary, theme.darkMode ? 0.10 : 0.06) : "transparent"
        return buttonArea.containsMouse ? theme.surfaceHover : theme.surface
    }

    border.width: root.variant === "secondary" || root.variant === "ghost" ? 1 : 0
    border.color: root.variant === "ghost"
        ? theme.tint(theme.primary, theme.darkMode ? 0.25 : 0.18)
        : theme.border

    Label {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: root.variant === "primary" || root.variant === "danger" ? "#FFFFFF" : theme.textPrimary
        font.family: theme.fontUi
        font.pixelSize: theme.sizeBody
        font.weight: 600
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        enabled: root.buttonEnabled
        hoverEnabled: true
        cursorShape: root.buttonEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    scale: buttonArea.pressed && root.buttonEnabled ? 0.985 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 80 } }
}
