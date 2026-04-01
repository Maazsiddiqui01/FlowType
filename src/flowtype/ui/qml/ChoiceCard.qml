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

    height: root.compact ? 60 : 72
    radius: theme.radiusCard
    border.width: root.selected ? 2 : 1
    border.color: root.selected ? root.accent : theme.border
    color: root.selected
        ? theme.tint(root.accent, theme.darkMode ? 0.08 : 0.04)
        : (mouseArea.containsMouse ? theme.surfaceHover : theme.surfaceMuted)

    RowLayout {
        anchors.fill: parent
        anchors.margins: theme.space16
        spacing: theme.space12

        ProviderBadge {
            providerId: root.providerId
            badgeText: root.badge
            accentColor: root.accent
            visible: !root.compact || root.badge.length > 0 || root.providerId.length > 0
            width: root.compact ? 34 : 40
            height: root.compact ? 34 : 40
        }

        Column {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: root.title
                color: root.selected ? root.accent : theme.textPrimary
                font.family: theme.fontText
                font.pixelSize: theme.sizeCardTitle
                font.weight: Font.DemiBold
            }

            Label {
                text: root.subtitle
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeHelper
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Rectangle {
            visible: !root.hideChevron
            Layout.alignment: Qt.AlignVCenter
            width: 20
            height: 20
            radius: 10
            border.width: root.selected ? 6 : 2
            border.color: root.selected ? root.accent : theme.textTertiary
            color: "transparent"

            Behavior on border.width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
}
