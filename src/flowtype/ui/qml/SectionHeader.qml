import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string title: ""
    property string subtitle: ""
    default property alias trailing: trailingHost.data

    implicitHeight: contentRow.implicitHeight

    RowLayout {
        id: contentRow
        anchors.fill: parent
        spacing: theme.space16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: theme.space4

            Label {
                text: root.title
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizeSectionTitle
                font.weight: 700
            }

            Label {
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeHelper
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        RowLayout {
            id: trailingHost
            spacing: theme.space8
        }
    }
}
