import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property color tone: theme.textSecondary

    height: theme.chipHeight
    width: chipText.implicitWidth + 24
    radius: height / 2
    color: "transparent"
    border.width: 1
    border.color: theme.tint(root.tone, 0.4)

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.tone
        opacity: theme.darkMode ? 0.12 : 0.08
    }

    Label {
        id: chipText
        anchors.centerIn: parent
        text: root.label
        color: root.tone
        font.family: theme.fontUi
        font.pixelSize: theme.sizeLabel
        font.weight: Font.DemiBold
    }
}
