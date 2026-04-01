import QtQuick
import QtQuick.Controls

Item {
    id: root

    Theme { id: theme }

    property string title: ""
    property string message: ""
    property string buttonText: ""

    signal actionClicked()

    implicitWidth: parent ? parent.width : 360
    implicitHeight: Math.max(180, contentColumn.implicitHeight + 32)

    Column {
        id: contentColumn
        anchors.centerIn: parent
        width: Math.min(root.width, 420)
        spacing: theme.space12

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 36
            height: 36
            radius: 18
            color: theme.surfaceMuted
            border.width: 1
            border.color: theme.border
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            color: theme.textPrimary
            font.family: theme.fontDisplay
            font.pixelSize: theme.sizeSectionTitle
            font.weight: 700
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(380, root.width - 24)
            text: root.message
            color: theme.textSecondary
            font.family: theme.fontText
            font.pixelSize: theme.sizeBody
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        FlowButton {
            visible: root.buttonText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            label: root.buttonText
            variant: "secondary"
            onClicked: root.actionClicked()
        }
    }
}
