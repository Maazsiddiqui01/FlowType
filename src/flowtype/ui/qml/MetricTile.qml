import QtQuick
import QtQuick.Controls

SurfacePanel {
    id: root

    Theme { id: theme }

    property string value: ""
    property string label: ""
    property color tone: "#7dd3fc"

    prominent: false
    accent: tone
    implicitWidth: 216
    implicitHeight: 112
    showAccentBar: false
    showOrb: false
    borderTone: theme.border

    Column {
        width: parent.width
        anchors.fill: parent
        anchors.margins: theme.cardPadding
        spacing: theme.space12

        Rectangle {
            width: 34
            height: 34
            radius: 11
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

        Item {
            width: 1
            height: 4
        }

        Label {
            text: root.value
            color: theme.textPrimary
            font.family: theme.fontDisplay
            font.pixelSize: theme.textMetric
            font.weight: Font.Black
        }

        Label {
            text: root.label
            color: theme.textSecondary
            font.family: theme.fontUi
            font.pixelSize: theme.textHelper
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
