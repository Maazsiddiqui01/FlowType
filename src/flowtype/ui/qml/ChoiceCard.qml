import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string title: ""
    property string subtitle: ""
    property string meta: ""
    property string badge: ""
    property string providerId: ""
    property color accent: theme.primary
    property bool selected: false
    property bool compact: false
    property bool hideChevron: false
    signal clicked()

    radius: theme.radiusCard
    color: selected ? theme.tint(root.accent, 0.08) : theme.surface
    border.width: 1
    border.color: selected ? theme.tint(root.accent, 0.36) : theme.border
    implicitHeight: compact ? 68 : 88

    RowLayout {
        anchors.fill: parent
        anchors.margins: compact ? 14 : theme.space16
        spacing: theme.space12

        ProviderBadge {
            badge: root.badge.length > 0 ? root.badge : root.title.slice(0, 2).toUpperCase()
            providerId: root.providerId
            compact: root.compact
            accent: root.accent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: theme.space8

                Label {
                    Layout.fillWidth: true
                    text: root.title
                    color: theme.textPrimary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeCardTitle
                    font.weight: 650
                    elide: Text.ElideRight
                }

                Label {
                    visible: root.meta.length > 0
                    text: root.meta
                    color: theme.textTertiary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeLabel
                    font.weight: 600
                }
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

        Rectangle {
            visible: !root.hideChevron
            width: 18
            height: 18
            radius: 9
            color: root.selected ? theme.tint(root.accent, 0.14) : theme.surfaceSubtle
            border.width: 1
            border.color: root.selected ? theme.tint(root.accent, 0.24) : theme.border

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: root.selected ? root.accent : "transparent"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
