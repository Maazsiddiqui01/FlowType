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

    implicitWidth: buttonLabel.implicitWidth + (root.compact ? 28 : 36)
    implicitHeight: root.compact ? theme.controlHeightCompact : theme.buttonHeight
    radius: theme.radiusControl
    antialiasing: true
    opacity: root.buttonEnabled ? 1.0 : 0.45
    activeFocusOnTab: root.buttonEnabled

    color: {
        if (root.variant === "primary")
            return buttonArea.pressed ? theme.primaryPressed : (buttonArea.containsMouse ? theme.primaryHover : root.accent)
        if (root.variant === "danger")
            return buttonArea.pressed ? Qt.darker(theme.error, 1.1) : (buttonArea.containsMouse ? Qt.lighter(theme.error, 1.05) : theme.error)
        if (root.variant === "ghost")
            return buttonArea.containsMouse ? theme.tint(theme.primary, theme.darkMode ? 0.12 : 0.08) : "transparent"
        return buttonArea.pressed ? theme.surfaceActive : (buttonArea.containsMouse ? theme.surfaceHover : theme.surface)
    }

    border.width: root.variant === "secondary" || root.variant === "ghost" ? 1 : 0
    border.color: root.variant === "ghost"
        ? theme.tint(theme.primary, theme.darkMode ? 0.25 : 0.18)
        : theme.border

    // Primary buttons get a subtle top sheen so they read as a raised glass key.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: root.variant === "primary" || root.variant === "danger"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
        }
    }

    // Keyboard focus ring (WCAG 2.4.7), drawn just outside the control.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -theme.focusRingOffset
        radius: root.radius + theme.focusRingOffset
        color: "transparent"
        border.width: theme.focusRingWidth
        border.color: theme.focusRing
        visible: root.activeFocus
    }

    Label {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: root.variant === "primary" || root.variant === "danger" ? theme.textOnAccent : theme.textPrimary
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

    Keys.onPressed: function(event) {
        if (root.buttonEnabled && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            root.clicked()
            event.accepted = true
        }
    }

    scale: buttonArea.pressed && root.buttonEnabled ? 0.98 : 1.0

    Behavior on color { ColorAnimation { duration: theme.durFast } }
    Behavior on border.color { ColorAnimation { duration: theme.durFast } }
    Behavior on scale { NumberAnimation { duration: 80; easing.type: theme.easeOut } }
    Behavior on opacity { NumberAnimation { duration: theme.durBase } }
}
