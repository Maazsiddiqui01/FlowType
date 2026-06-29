import QtQuick

Rectangle {
    id: root

    Theme { id: theme }

    property color baseColor: theme.surface
    property color borderTone: theme.border
    property int panelPadding: theme.cardPadding
    // Kept for API/intent; depth is conveyed by the sheen + ramp + borders rather
    // than a shader/FBO effect, so cards always render regardless of GPU/driver.
    property int elevation: 1
    // Adds the top-edge frost highlight + bottom depth that sells the glass look.
    property bool glass: true

    default property alias panelChildren: contentItem.data

    radius: theme.radiusCard
    color: root.baseColor
    border.width: 1
    border.color: root.borderTone
    antialiasing: true
    implicitWidth: 240
    implicitHeight: Math.max(contentItem.childrenRect.height + root.panelPadding * 2, 64)

    // Glass sheen: a brighter top edge fading to a subtle base shade. Pure gradient
    // (no shader) so it renders identically on every backend.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.glass
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.glassHighlight }
            GradientStop { position: 0.42; color: "transparent" }
            GradientStop { position: 1.0; color: theme.glassLowlight }
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
