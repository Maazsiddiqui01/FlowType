import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property color tone: theme.textSecondary

    implicitWidth: chipText.implicitWidth + 22
    implicitHeight: theme.chipHeight
    radius: theme.radiusPill
    color: theme.tint(root.tone, theme.darkMode ? 0.12 : 0.08)
    border.width: 1
    border.color: theme.tint(root.tone, theme.darkMode ? 0.32 : 0.18)

    Label {
        id: chipText
        anchors.centerIn: parent
        text: root.label
        color: root.tone
        font.family: theme.fontUi
        font.pixelSize: theme.sizeLabel
        font.weight: 600
    }
}
