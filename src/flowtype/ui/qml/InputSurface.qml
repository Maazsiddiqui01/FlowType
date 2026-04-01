import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    default property alias content: contentRect.data
    property bool errorState: false

    radius: theme.radiusControl
    color: theme.surfaceSubtle
    border.width: 1
    border.color: root.errorState ? theme.error : (hoverArea.containsMouse ? theme.borderSelected : theme.border)

    Item {
        id: contentRect
        anchors.fill: parent
        anchors.margins: 12
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }

    Behavior on border.color { ColorAnimation { duration: 120 } }
}
