import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string title: ""
    property string subtitle: ""
    property alias trailing: trailingSlot.data

    implicitWidth: headerLayout.implicitWidth
    implicitHeight: headerLayout.implicitHeight

    RowLayout {
        id: headerLayout
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
                Layout.fillWidth: true
                text: root.subtitle
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeHelper
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: trailingSlot
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }
    }
}
