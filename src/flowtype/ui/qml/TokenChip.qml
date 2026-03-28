import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property alias text: root.label
    property color tone: theme.primary
    property bool subtle: true

    radius: theme.radiusPill
    color: subtle ? theme.tint(root.tone, 0.08) : root.tone
    border.width: 1
    border.color: subtle ? theme.tint(root.tone, 0.2) : root.tone
    implicitWidth: chipLabel.implicitWidth + 16
    implicitHeight: theme.chipHeight

    Label {
        id: chipLabel
        anchors.centerIn: parent
        text: root.label
        color: subtle ? theme.textPrimary : "#ffffff"
        font.family: theme.fontText
        font.pixelSize: theme.sizeLabel
        font.weight: 600
    }
}
