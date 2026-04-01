import QtQuick
import QtQuick.Controls

Flickable {
    id: root

    Theme { id: theme }

    default property alias content: contentLayout.data
    property int maxContentWidth: 1120
    property int contentSpacing: theme.sectionGap

    clip: true
    contentWidth: width
    contentHeight: contentLayout.implicitHeight + theme.shellPadding * 2
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        width: 8
        contentItem: Rectangle {
            radius: 4
            color: theme.darkMode ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(20, 50, 74, 0.16)
        }
    }

    Column {
        id: contentLayout
        x: theme.shellPadding
        y: theme.shellPadding
        width: Math.max(320, Math.min(root.maxContentWidth, root.width - theme.shellPadding * 2))
        spacing: root.contentSpacing
    }
}
