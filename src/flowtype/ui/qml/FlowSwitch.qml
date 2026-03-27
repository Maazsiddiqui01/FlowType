import QtQuick

Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 50
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "#c8f3ee" : "#edf3f6"
        border.width: 1
        border.color: root.checked ? "#67d1c5" : "#d7e2e8"

        Rectangle {
            width: 22
            height: 22
            radius: 11
            y: 4
            x: root.checked ? parent.width - width - 4 : 4
            color: root.checked ? "#0d9488" : "#ffffff"
            border.width: 1
            border.color: root.checked ? "#0d9488" : "#d0dde4"

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
