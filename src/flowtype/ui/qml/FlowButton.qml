import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string label: ""
    property string variant: "secondary"
    property color accent: "#2563eb"
    property bool compact: false
    property bool fillWidth: false
    property bool emphasized: false
    property bool buttonEnabled: true
    signal clicked()

    implicitWidth: fillWidth ? 180 : Math.max(compact ? 100 : 118, buttonLabel.implicitWidth + (compact ? 28 : 34))
    implicitHeight: compact ? 38 : 44
    radius: compact ? 14 : 16
    scale: root.buttonEnabled && mouseArea.pressed ? 0.986 : 1.0
    opacity: root.buttonEnabled ? 1.0 : 0.52

    function backgroundColor() {
        if (variant === "primary")
            return mouseArea.pressed ? Qt.darker(accent, 1.1) : (mouseArea.containsMouse ? Qt.lighter(accent, 1.04) : accent)
        if (variant === "success")
            return mouseArea.pressed ? "#0b857b" : (mouseArea.containsMouse ? "#0fa396" : "#0d9488")
        if (variant === "warm")
            return mouseArea.pressed ? "#dc7a09" : (mouseArea.containsMouse ? "#ef9a21" : "#eb8a0e")
        if (variant === "danger")
            return mouseArea.pressed ? "#d96a61" : (mouseArea.containsMouse ? "#ea8279" : "#e57268")
        return mouseArea.containsMouse ? "#f3f8fb" : "#ffffff"
    }

    function borderTone() {
        if (variant === "primary")
            return Qt.darker(accent, 1.05)
        if (variant === "success")
            return "#0b857b"
        if (variant === "warm")
            return "#dd7d06"
        if (variant === "danger")
            return "#da6c62"
        return mouseArea.containsMouse ? "#c5d7e1" : "#d9e5ec"
    }

    function textTone() {
        return variant === "secondary" ? "#173042" : "#ffffff"
    }

    color: backgroundColor()
    border.width: 1
    border.color: borderTone()

    Rectangle {
        visible: variant !== "secondary"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        height: parent.height * 0.46
        radius: parent.radius - 1
        color: "#ffffff"
        opacity: emphasized ? 0.2 : 0.11
    }

    Label {
        id: buttonLabel
        anchors.centerIn: parent
        text: root.label
        color: root.textTone()
        font.family: "Segoe UI Variable Text"
        font.pixelSize: compact ? 12 : 13
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
