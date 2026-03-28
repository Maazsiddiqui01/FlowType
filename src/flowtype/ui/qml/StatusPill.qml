import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string statusText: "Ready"
    property alias text: root.statusText
    property color tone: theme.teal

    radius: theme.radiusPill
    color: theme.surface
    border.width: 1
    border.color: theme.tint(root.tone, 0.24)
    implicitWidth: row.implicitWidth + 16
    implicitHeight: theme.controlHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: theme.space8

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: root.tone
        }

        Label {
            text: root.statusText
            color: theme.textPrimary
            font.family: theme.fontText
            font.pixelSize: theme.sizeLabel
            font.weight: 600
        }
    }
}
