import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string statusText: "Ready"
    property alias text: root.statusText
    property color tone: theme.teal

    implicitWidth: statusRow.implicitWidth + 18
    implicitHeight: theme.controlHeightCompact
    radius: theme.radiusPill
    color: theme.surface
    border.width: 1
    border.color: theme.tint(root.tone, theme.darkMode ? 0.34 : 0.2)

    RowLayout {
        id: statusRow
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
            font.family: theme.fontUi
            font.pixelSize: theme.sizeLabel
            font.weight: 650
        }
    }
}
