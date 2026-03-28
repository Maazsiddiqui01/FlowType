import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    property color accent: theme.primary
    property int padding: theme.cardPadding
    property int cornerRadius: theme.radiusCard
    property bool prominent: false
    property bool showAccentBar: false
    property bool showOrb: false
    property bool outlined: true
    property color baseColor: prominent ? theme.surface : theme.surface
    property color borderTone: outlined ? theme.border : "transparent"
    default property alias contentData: contentItem.data

    color: baseColor
    radius: cornerRadius
    border.width: outlined ? 1 : 0
    border.color: borderTone
    implicitHeight: Math.max(contentItem.implicitHeight + (padding * 2), 72)

    Rectangle {
        visible: root.showAccentBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        height: 2
        radius: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.tint(root.accent, 0.68) }
            GradientStop { position: 1.0; color: theme.tint(root.accent, 0.0) }
        }
    }

    Rectangle {
        visible: root.showOrb
        width: Math.min(parent.width * 0.12, 72)
        height: width
        radius: width / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -width * 0.34
        anchors.rightMargin: -width * 0.16
        color: root.accent
        opacity: root.prominent ? 0.035 : 0.018
    }

    Item {
        id: contentItem
        x: root.padding
        y: root.padding
        width: root.width - (root.padding * 2)
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        height: root.height > 0 ? Math.max(root.height - (root.padding * 2), implicitHeight) : implicitHeight
    }

    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on color { ColorAnimation { duration: 140 } }
}
