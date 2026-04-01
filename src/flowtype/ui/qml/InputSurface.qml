import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    default property alias content: contentRect.data
    property bool errorState: false

    radius: theme.radiusControl
    color: theme.appBackground
    border.width: root.errorState ? 1 : 1
    border.color: root.errorState ? theme.error : (inputMouseArea.containsMouse ? theme.borderSelected : theme.border)

    Item {
        id: contentRect
        anchors.fill: parent
        anchors.margins: 12
    }

    MouseArea {
        id: inputMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Behavior on border.color { ColorAnimation { duration: 150 } }
}
