import QtQuick
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string icon: "ℹ️"
    property string title: ""
    property string message: ""
    property string buttonText: ""
    
    signal actionClicked()

    width: parent.width
    height: Math.max(220, mainCol.implicitHeight + 40)

    Column {
        id: mainCol
        anchors.centerIn: parent
        spacing: theme.space16

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            font.pixelSize: 42
            color: theme.textTertiary
            opacity: 0.6
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: theme.space4
            
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.title
                color: theme.textSecondary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizeSectionTitle
                font.weight: Font.DemiBold
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(360, root.width - 40)
                text: root.message
                color: theme.textTertiary
                font.family: theme.fontText
                font.pixelSize: theme.sizeBody
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
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
