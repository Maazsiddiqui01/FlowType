import QtQuick
import QtQuick.Controls

ScrollView {
    id: root

    Theme { id: theme }

    property int maxContentWidth: 1160
    property int contentSpacing: theme.sectionGap
    property int contentLeftMargin: 0
    default property alias pageChildren: contentColumn.data

    clip: true
    contentWidth: availableWidth
    contentHeight: container.height

    Item {
        id: container
        width: root.availableWidth
        height: contentColumn.implicitHeight

        Column {
            id: contentColumn
            width: Math.min(Math.max(0, root.availableWidth - root.contentLeftMargin), root.maxContentWidth)
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: root.contentLeftMargin
            spacing: root.contentSpacing
        }
    }

    ScrollBar.vertical.policy: ScrollBar.AsNeeded
}
