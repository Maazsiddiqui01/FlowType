import QtQuick
import QtQuick.Controls

ScrollView {
    id: root

    property int maxContentWidth: 1160
    property int contentSpacing: 18
    default property alias pageChildren: contentColumn.data

    clip: true
    contentWidth: availableWidth
    contentHeight: container.height

    Item {
        id: container
        width: Math.max(root.availableWidth, contentColumn.width)
        height: contentColumn.implicitHeight

        Column {
            id: contentColumn
            width: Math.min(root.availableWidth, root.maxContentWidth)
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.contentSpacing
        }
    }
}
