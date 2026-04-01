import QtQuick

SurfacePanel {
    id: root
    
    Theme { id: theme }

    property color baseColor: theme.surface
    property color borderTone: theme.border

    color: root.baseColor
    border.color: root.borderTone
    radius: theme.radiusGlass || theme.radiusCard
}
