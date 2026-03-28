import QtQuick

Item {
    id: root

    Theme { id: theme }

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? theme.tint(theme.teal, 0.16) : theme.surfaceSubtle
        border.width: 1
        border.color: root.checked ? theme.tint(theme.teal, 0.34) : theme.border

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 4
            x: root.checked ? parent.width - width - 4 : 4
            color: root.checked ? theme.teal : "#ffffff"
            border.width: 1
            border.color: root.checked ? theme.teal : theme.border

            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
