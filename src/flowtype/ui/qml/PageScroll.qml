import QtQuick
import QtQuick.Controls

Flickable {
    id: root
    
    Theme { id: theme }
    
    default property alias content: contentLayout.data
    property int maxContentWidth: 900
    property int contentSpacing: theme.space24
    
    contentWidth: width
    contentHeight: contentLayout.height + theme.shellPadding * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Desktop style custom scrollbar
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        width: 8
        contentItem: Rectangle {
            radius: 4
            color: theme.darkMode ? Qt.rgba(1,1,1,0.15) : Qt.rgba(0,0,0,0.15)
        }
    }

    Column {
        id: contentLayout
        width: Math.min(parent.width - theme.shellPadding * 2, root.maxContentWidth)
        anchors.top: parent.top
        anchors.topMargin: theme.shellPadding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.contentSpacing
    }
}
