import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    property int padding: 12
    property color borderTone: theme.border
    property color fill: theme.surface
    default property alias contentData: contentHost.data

    radius: theme.radiusControl
    color: root.fill
    border.width: 1
    border.color: root.borderTone
    implicitHeight: Math.max(theme.controlHeight, contentHost.implicitHeight + (padding * 2))

    Item {
        id: contentHost
        x: root.padding
        y: root.padding
        width: root.width - (root.padding * 2)
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        height: root.height - (root.padding * 2)
    }
}
