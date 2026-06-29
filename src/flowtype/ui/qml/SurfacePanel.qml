import QtQuick

// A card surface with a real soft shadow for depth. Was a bare Rectangle; now an
// Item that draws SoftShadow behind an opaque card + a glass sheen, while preserving
// the original API (baseColor / borderTone / radius / panelPadding / panelChildren).
Item {
    id: root

    Theme { id: theme }

    property color baseColor: theme.surface
    property color borderTone: theme.border
    property int panelPadding: theme.cardPadding
    property int radius: theme.radiusCard
    // 0 = flat (no shadow), 1 = resting card, 2 = raised (popovers/modals).
    property int elevation: 1
    property bool glass: true

    default property alias panelChildren: contentItem.data

    implicitWidth: 240
    implicitHeight: Math.max(contentItem.childrenRect.height + root.panelPadding * 2, 64)

    SoftShadow {
        anchors.fill: card
        radius: root.radius
        visible: root.elevation > 0
        shadowColor: theme.shadowColor
        spread: root.elevation >= 2 ? 28 : 15
        verticalOffset: root.elevation >= 2 ? 12 : 5
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: root.radius
        color: root.baseColor
        border.width: 1
        border.color: root.borderTone
        antialiasing: true

        // Glass sheen: brighter top edge fading to a subtle base shade (pure gradient).
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.glass
            gradient: Gradient {
                GradientStop { position: 0.0; color: theme.glassHighlight }
                GradientStop { position: 0.45; color: "transparent" }
                GradientStop { position: 1.0; color: theme.glassLowlight }
            }
        }
    }

    Item {
        id: contentItem
        x: root.panelPadding
        y: root.panelPadding
        width: root.width - root.panelPadding * 2
        height: childrenRect.height
    }
}
