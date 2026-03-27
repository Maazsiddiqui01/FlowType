import QtQuick

Rectangle {
    id: root

    property string badge: "FT"
    property color badgeBackground: "#f0f7fb"
    property color badgeForeground: "#173042"
    property color accent: "#2563eb"
    property bool compact: false

    implicitWidth: compact ? 30 : 38
    implicitHeight: compact ? 30 : 38
    radius: compact ? 11 : 13
    color: badgeBackground
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.2)

    Text {
        anchors.centerIn: parent
        text: root.badge
        color: root.badgeForeground
        font.family: "Bahnschrift SemiBold"
        font.pixelSize: compact ? 11 : 13
    }
}
