import QtQuick

Rectangle {
    id: root

    property color accent: "#0d9488"
    property int padding: 20
    property int cornerRadius: 22
    property bool prominent: false
    property bool showAccentBar: false
    property bool showOrb: false
    property color baseColor: prominent ? "#ffffff" : "#fbfdfe"
    default property alias contentData: contentItem.data

    color: baseColor
    radius: cornerRadius
    border.width: 1
    border.color: prominent ? "#dce6ed" : "#e7eef3"
    implicitHeight: Math.max(contentItem.implicitHeight + (padding * 2), 92)

    Rectangle {
        visible: root.showAccentBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 0
        height: 2
        radius: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7) }
            GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.0) }
        }
    }

    Rectangle {
        visible: root.showOrb
        width: Math.min(parent.width * 0.18, 104)
        height: width
        radius: width / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -width * 0.34
        anchors.rightMargin: -width * 0.16
        color: root.accent
        opacity: root.prominent ? 0.025 : 0.015
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
}
