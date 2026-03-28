import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property string variant: "secondary"
    property color accent: theme.primary
    property bool compact: false
    property bool fillWidth: false
    property bool emphasized: false
    property bool buttonEnabled: true
    signal clicked()

    implicitWidth: fillWidth ? 180 : Math.max(compact ? 92 : 112, buttonLabel.implicitWidth + (compact ? 28 : 34))
    implicitHeight: compact ? theme.controlHeightCompact : theme.buttonHeight
    radius: theme.radiusControl
    scale: root.buttonEnabled && mouseArea.pressed ? 0.986 : 1.0
    opacity: root.buttonEnabled ? 1.0 : 0.52

    function backgroundColor() {
        if (variant === "primary")
            return mouseArea.pressed ? Qt.darker(accent, 1.08) : (mouseArea.containsMouse ? Qt.lighter(accent, 1.03) : accent)
        if (variant === "success")
            return mouseArea.pressed ? Qt.darker(theme.teal, 1.08) : (mouseArea.containsMouse ? Qt.lighter(theme.teal, 1.03) : theme.teal)
        if (variant === "warm")
            return mouseArea.pressed ? Qt.darker(theme.warm, 1.08) : (mouseArea.containsMouse ? Qt.lighter(theme.warm, 1.03) : theme.warm)
        if (variant === "danger")
            return mouseArea.pressed ? Qt.darker(theme.error, 1.08) : (mouseArea.containsMouse ? Qt.lighter(theme.error, 1.03) : theme.error)
        if (variant === "neutral")
            return mouseArea.containsMouse ? theme.surface : theme.surfaceSubtle
        return mouseArea.containsMouse ? theme.surfaceSubtle : theme.surface
    }

    function borderTone() {
        if (variant === "primary")
            return Qt.darker(accent, 1.04)
        if (variant === "success")
            return Qt.darker(theme.teal, 1.04)
        if (variant === "warm")
            return Qt.darker(theme.warm, 1.04)
        if (variant === "danger")
            return Qt.darker(theme.error, 1.04)
        if (variant === "neutral")
            return mouseArea.containsMouse ? theme.border : theme.divider
        return mouseArea.containsMouse ? theme.textTertiary : theme.border
    }

    function textTone() {
        return variant === "primary" || variant === "success" || variant === "warm" || variant === "danger"
            ? "#ffffff"
            : theme.textPrimary
    }

    color: backgroundColor()
    border.width: 1
    border.color: borderTone()

    Rectangle {
        visible: variant === "primary" || variant === "success" || variant === "warm" || variant === "danger"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: parent.height * 0.46
        radius: parent.radius - 1
        color: "#ffffff"
        opacity: emphasized ? 0.18 : 0.1
    }

    Label {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: root.textTone()
        font.family: theme.fontUi
        font.pixelSize: compact ? theme.textLabel : theme.textBody
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.buttonEnabled
        hoverEnabled: root.buttonEnabled
        cursorShape: root.buttonEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
}
