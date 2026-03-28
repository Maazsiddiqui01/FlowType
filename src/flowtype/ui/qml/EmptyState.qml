import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string title: ""
    property string message: ""

    implicitHeight: 84

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, 420)
        spacing: theme.space8

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            color: theme.textPrimary
            font.family: theme.fontText
            font.pixelSize: theme.sizeCardTitle
            font.weight: 650
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.message
            color: theme.textSecondary
            font.family: theme.fontText
            font.pixelSize: theme.sizeBody
            wrapMode: Text.WordWrap
        }
    }
}
