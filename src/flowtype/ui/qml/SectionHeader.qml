import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string title: ""
    property string subtitle: ""
    property alias trailing: trailingContainer.data

    implicitWidth: parent ? parent.width : headerRow.implicitWidth
    implicitHeight: headerRow.implicitHeight

    RowLayout {
        id: headerRow
        anchors.fill: parent
        spacing: theme.space16

        Column {
            Layout.fillWidth: true
            spacing: theme.space4

            Label {
                text: root.title
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizeSectionTitle
                font.weight: Font.DemiBold
            }

            Label {
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeBody
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Item {
            id: trailingContainer
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            Layout.preferredHeight: childrenRect.height
            Layout.preferredWidth: childrenRect.width
        }
    }
}
