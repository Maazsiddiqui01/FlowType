import QtQuick

Item {
    id: root

    Theme { id: theme }

    property bool checked: false

    signal clicked()
    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? theme.primary : (theme.darkMode ? "#273142" : "#D9E1EC")
        border.width: 1
        border.color: root.checked ? theme.primary : theme.border

        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: "#FFFFFF"

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
            root.clicked()
        }
    }
}
