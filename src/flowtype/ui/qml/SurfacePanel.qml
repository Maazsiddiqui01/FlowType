import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    property color baseColor: theme.surface
    property bool prominent: false
    property color accent: theme.primary
    property bool showAccentBar: false
    property bool showOrb: false
    property color borderTone: theme.border

    default property alias panelChildren: contentItem.data

    radius: theme.radiusCard
    color: root.baseColor
    border.width: 1
    border.color: root.borderTone
    implicitHeight: contentItem.implicitHeight + 2 * theme.cardPadding
    implicitWidth: 200

    // Top edge highlight for glass effect
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        height: 1
        radius: parent.radius
        color: theme.glassHighlight
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: theme.cardPadding
    }
}
