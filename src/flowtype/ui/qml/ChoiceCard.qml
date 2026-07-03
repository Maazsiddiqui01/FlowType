import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

/*
 * Selectable option card, logo-forward. Selection reads as an accent-tinted
 * border + a small check chip in the top-right corner (no radio dot competing
 * with the content). Hover brightens the border and lifts the fill slightly.
 */
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
    property bool hideChevron: false // kept for API compatibility; check chip replaces the chevron

    signal clicked()

    implicitHeight: root.compact ? 60 : 84
    radius: theme.radiusCard
    antialiasing: true
    activeFocusOnTab: true
    color: root.selected
        ? theme.tint(root.accent, theme.darkMode ? 0.12 : 0.07)
        : (choiceArea.containsMouse ? theme.surfaceHover : theme.surface)
    border.width: 1
    border.color: root.selected
        ? theme.tint(root.accent, theme.darkMode ? 0.60 : 0.40)
        : (choiceArea.containsMouse ? theme.borderSelected : theme.border)

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Soft inner top sheen so cards don't read flat
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: parent.height * 0.5
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, theme.darkMode ? 0.03 : 0.25) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Focus ring (keyboard accessibility)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -theme.focusRingOffset
        radius: root.radius + theme.focusRingOffset
        color: "transparent"
        border.width: theme.focusRingWidth
        border.color: theme.focusRing
        visible: root.activeFocus
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked()
            event.accepted = true
        }
    }

    // Check chip, top-right — the single selection signal
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
        width: 18
        height: 18
        radius: 9
        color: root.accent
        visible: root.selected

        // Vector check mark (Shape, consistent with NavIcon/ProviderBadge rendering)
        Shape {
            anchors.fill: parent
            antialiasing: true

            ShapePath {
                strokeColor: "#FFFFFF"
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                fillColor: "transparent"
                PathSvg { path: "M5 9.4 7.9 12.2 13 6.3" }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: theme.space16
        anchors.rightMargin: theme.space16
        spacing: theme.space12

        ProviderBadge {
            providerId: root.providerId
            badgeText: root.badge
            accentColor: root.accent
            visible: root.badge.length > 0 || root.providerId.length > 0
            width: root.compact ? 34 : 40
            height: width
            radius: root.compact ? 10 : 12
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                Layout.fillWidth: true
                Layout.rightMargin: root.selected ? 18 : 0
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
    }

    MouseArea {
        id: choiceArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
