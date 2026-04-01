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

    width: buttonLabel.implicitWidth + (compact ? 24 : 32)
    height: compact ? theme.controlHeightCompact : theme.buttonHeight
    radius: compact ? theme.radiusControl : theme.radiusControl
    opacity: buttonEnabled ? 1.0 : 0.4

    color: {
        if (variant === "primary")
            return buttonMouseArea.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent
        if (variant === "success")
            return buttonMouseArea.containsMouse ? Qt.lighter(theme.teal, 1.12) : theme.teal
        if (variant === "danger")
            return buttonMouseArea.containsMouse ? Qt.lighter(theme.error, 1.12) : theme.error
        if (variant === "warm")
            return buttonMouseArea.containsMouse ? Qt.lighter(theme.warm, 1.12) : theme.warm
        // secondary
        return buttonMouseArea.containsMouse ? theme.surfaceHover : theme.surface
    }

    border.width: variant === "secondary" ? 1 : 0
    border.color: variant === "secondary" ? theme.border : "transparent"

    Label {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: {
            if (variant === "secondary") return theme.textPrimary
            if (variant === "warm") return "#1A1400"
            return "#FFFFFF"
        }
        font.family: theme.fontText
        font.pixelSize: compact ? theme.sizeLabel : theme.sizeBody
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: buttonMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.buttonEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.buttonEnabled) root.clicked()
        }
    }

    Behavior on color { ColorAnimation { duration: 120 } }

    // subtle scale press effect
    scale: buttonMouseArea.pressed && root.buttonEnabled ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
}
