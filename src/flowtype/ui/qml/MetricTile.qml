import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string label: ""
    property string value: ""
    property color tone: theme.primary

    implicitHeight: 116
    radius: theme.radiusCard
    color: theme.surface
    border.width: 1
    border.color: theme.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.space16
        spacing: theme.space12

        Rectangle {
            Layout.preferredWidth: 12
            Layout.preferredHeight: 12
            radius: 6
            color: root.tone
        }

        Label {
            text: root.value
            color: theme.textPrimary
            font.family: theme.fontDisplay
            font.pixelSize: theme.sizeMetric
            font.weight: 760
        }

        Label {
            Layout.fillWidth: true
            text: root.label
            color: theme.textSecondary
            font.family: theme.fontText
            font.pixelSize: theme.sizeHelper
            wrapMode: Text.WordWrap
        }
    }
}
