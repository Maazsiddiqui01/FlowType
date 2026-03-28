import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string title: ""
    property string detail: ""
    default property alias controls: controlHost.data

    radius: theme.radiusCard
    color: theme.surface
    border.width: 1
    border.color: theme.border
    implicitHeight: Math.max(72, row.implicitHeight + 24)

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: theme.space16
        spacing: theme.space16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: theme.space4

            Label {
                text: root.title
                color: theme.textPrimary
                font.family: theme.fontText
                font.pixelSize: theme.sizeCardTitle
                font.weight: 650
            }

            Label {
                visible: root.detail.length > 0
                text: root.detail
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeHelper
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        RowLayout {
            id: controlHost
            spacing: theme.space8
        }
    }
}
