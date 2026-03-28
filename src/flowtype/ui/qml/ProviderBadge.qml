import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    property string badge: "FT"
    property string providerId: ""
    property color badgeBackground: theme.surfaceSubtle
    property color badgeForeground: theme.textPrimary
    property color accent: theme.primary
    property bool compact: false

    implicitWidth: compact ? 28 : 36
    implicitHeight: compact ? 28 : 36
    radius: compact ? 10 : 12
    color: badgeBackground
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, compact ? 0.14 : 0.18)

    Image {
        id: iconImage
        anchors.centerIn: parent
        width: root.compact ? 15 : 20
        height: root.compact ? 15 : 20
        sourceSize.width: 64
        sourceSize.height: 64
        source: root.providerId !== "" ? Qt.resolvedUrl("../../../../assets/providers/" + root.providerId + ".svg") : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        text: root.badge
        color: root.badgeForeground
        font.family: theme.fontUi
        font.weight: Font.DemiBold
        font.pixelSize: compact ? theme.textLabel : theme.textBody
        visible: !iconImage.visible
    }
}
