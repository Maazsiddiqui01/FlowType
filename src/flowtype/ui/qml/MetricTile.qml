import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property string value: ""
    property color tone: theme.primary

    height: 96
    radius: theme.radiusCard
    color: theme.darkMode ? "#0F1219" : "#F8F9FC"
    border.width: 1
    border.color: theme.border

    // Top highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        height: 1
        radius: parent.radius
        color: theme.glassHighlight
    }

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: theme.space16
        spacing: theme.space4

        Row {
            spacing: theme.space8
            
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: root.tone
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Label {
                text: root.label
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeHelper
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Label {
            text: root.value
            color: theme.textPrimary
            font.family: theme.fontDisplay
            font.pixelSize: 28
            font.weight: Font.Bold
        }
    }
}
