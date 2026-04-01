import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string shortcut: ""
    property bool isRecording: false
    property string actionName: ""
    signal shortcutRecorded(string newShortcut)

    width: mainLayout.implicitWidth
    height: theme.controlHeightCompact

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: theme.space8

        Rectangle {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            radius: theme.radiusControl
            color: root.isRecording 
                ? theme.tint(theme.warm, theme.darkMode ? 0.2 : 0.1) 
                : (mouseArea.containsMouse ? theme.surfaceHover : theme.appBackground)
            border.width: 1
            border.color: root.isRecording ? theme.warm : theme.border

            Label {
                anchors.centerIn: parent
                text: root.isRecording 
                    ? "Press shortcut..." 
                    : (root.shortcut.length > 0 ? root.shortcut : "Unassigned")
                color: root.isRecording 
                    ? theme.warm 
                    : (root.shortcut.length > 0 ? theme.textPrimary : theme.textTertiary)
                font.family: theme.fontUi
                font.pixelSize: theme.sizeHelper
                font.weight: root.shortcut.length > 0 ? Font.DemiBold : Font.Normal
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!root.isRecording) AppController.startShortcutRecording(root.actionName)
            }
        }

        FlowButton {
            visible: root.shortcut.length > 0 && !root.isRecording
            label: "Clear"
            compact: true
            variant: "secondary"
            onClicked: root.shortcutRecorded("")
        }

        FlowButton {
            visible: root.isRecording
            label: "Cancel"
            compact: true
            variant: "secondary"
            onClicked: AppController.cancelShortcutRecording()
        }
    }
}
