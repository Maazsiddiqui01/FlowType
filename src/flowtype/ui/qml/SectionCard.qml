import QtQuick

SurfacePanel {
    id: root

    Theme { id: theme }

    prominent: false
    cornerRadius: theme.radiusCard
    padding: theme.cardPadding
    borderTone: theme.border
    baseColor: theme.surface
    showAccentBar: false
    showOrb: false
}
