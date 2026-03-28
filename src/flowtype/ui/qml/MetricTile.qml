import QtQuick
import QtQuick.Controls

SurfacePanel {
    id: root

    property string value: ""
    property string label: ""
    property color tone: "#7dd3fc"

    prominent: true
    accent: tone
    implicitWidth: 216
    implicitHeight: 126
    showAccentBar: false
    showOrb: false
    borderTone: "#dfe8ef"

    Column {
        width: parent.width
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 8

        Rectangle {
            width: 36
            height: 36
            radius: 12
            color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.16)
            border.width: 1
            border.color: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.22)

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 6
                color: root.tone
            }
        }

        Label {
            text: root.value
            color: "#113045"
            font.family: "Segoe UI Variable Display"
            font.pixelSize: 28
            font.weight: Font.Black
        }

        Label {
            text: root.label
            color: "#688193"
            font.family: "Segoe UI Variable Text"
            font.pixelSize: 12
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }
}
