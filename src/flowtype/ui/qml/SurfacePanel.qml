import QtQuick

Rectangle {
    id: root

    property color accent: "#0d9488"
    property int padding: 22
    property int cornerRadius: 24
    property bool prominent: false
    property color baseColor: prominent ? "#ffffff" : "#f8fbfd"
    default property alias contentData: contentItem.data

    color: baseColor
    radius: cornerRadius
    border.width: 1
    border.color: prominent ? "#d8e5ec" : "#e1ebf0"
    implicitHeight: Math.max(contentItem.implicitHeight + (padding * 2), 92)

    Rectangle {
        width: parent.width - 2
        height: 1
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#ffffff"
        opacity: 0.7
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 1
        height: 3
        radius: 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.78) }
            GradientStop { position: 1.0; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.0) }
        }
    }

    Rectangle {
        width: Math.min(parent.width * 0.18, 104)
        height: width
        radius: width / 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -width * 0.34
        anchors.rightMargin: -width * 0.16
        color: root.accent
        opacity: root.prominent ? 0.05 : 0.03
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
