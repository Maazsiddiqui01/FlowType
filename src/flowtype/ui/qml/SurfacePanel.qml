import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    property color baseColor: theme.surface
    property color borderTone: theme.border
    property int panelPadding: theme.cardPadding

    default property alias panelChildren: contentItem.data

    radius: theme.radiusCard
    color: root.baseColor
    border.width: 1
    border.color: root.borderTone
    implicitWidth: 240
    implicitHeight: Math.max(contentItem.childrenRect.height + root.panelPadding * 2, 64)

    Item {
        id: contentItem
        x: root.panelPadding
        y: root.panelPadding
        width: root.width - root.panelPadding * 2
        height: childrenRect.height
    }
}
