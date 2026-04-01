import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    property string title: ""
    property string subtitle: ""
    property string providerId: ""
    property string badge: ""
    property color accent: theme.primary
    property bool selected: false
    property bool compact: false
    property bool hideChevron: false

    signal clicked()

    implicitHeight: root.compact ? 64 : 88
    radius: theme.radiusCard
    color: root.selected
        ? theme.tint(root.accent, theme.darkMode ? 0.14 : 0.08)
        : (choiceArea.containsMouse ? theme.surfaceHover : theme.surface)
    border.width: 1
    border.color: root.selected ? theme.tint(root.accent, theme.darkMode ? 0.55 : 0.35) : theme.border

    RowLayout {
        anchors.fill: parent
        anchors.margins: theme.space16
        spacing: theme.space12

        ProviderBadge {
            providerId: root.providerId
            badgeText: root.badge
            accentColor: root.selected ? root.accent : theme.textSecondary
            visible: root.badge.length > 0 || root.providerId.length > 0
            width: root.compact ? 34 : 38
            height: width
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

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
                visible: root.subtitle.length > 0
                Layout.fillWidth: true
                text: root.subtitle
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeHelper
                wrapMode: Text.WordWrap
                maximumLineCount: root.compact ? 1 : 2
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: !root.hideChevron
            Layout.alignment: Qt.AlignVCenter
            width: 18
            height: 18
            radius: 9
            color: root.selected ? root.accent : "transparent"
            border.width: root.selected ? 0 : 1
            border.color: theme.borderSelected

            Rectangle {
                anchors.centerIn: parent
                visible: root.selected
                width: 6
                height: 6
                radius: 3
                color: "#FFFFFF"
            }
        }
    }

    MouseArea {
        id: choiceArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
}
