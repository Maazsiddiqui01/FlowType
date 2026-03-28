import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string label: ""
    property string value: ""
    property color valueColor: theme.textPrimary

    implicitHeight: 20

    RowLayout {
        anchors.fill: parent
        spacing: theme.space12

        Label {
            text: root.label
            color: theme.textSecondary
            font.family: theme.fontText
            font.pixelSize: theme.sizeHelper
        }

        Item { Layout.fillWidth: true }

        Label {
            text: root.value
            color: root.valueColor
            font.family: theme.fontText
            font.pixelSize: theme.sizeHelper
            font.weight: 600
            elide: Text.ElideRight
        }
    }
}
