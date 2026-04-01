import QtQuick

Row {
    id: root

    Theme { id: theme }

    property int bars: 9
    property int barWidth: 4
    property int gap: 3
    property int minimumBarHeight: 3
    property int maximumBarHeight: 18
    property real level: 0.0
    property string mode: "idle"

    // Smoothed level with fast attack, slow decay for visual appeal
    property real _smoothLevel: 0.0

    on_SmoothLevelChanged: {}
    onLevelChanged: {
        if (level > _smoothLevel)
            _smoothLevel = _smoothLevel + (level - _smoothLevel) * 0.7  // fast attack
        else
            _smoothLevel = _smoothLevel + (level - _smoothLevel) * 0.15 // slow decay
    }

    property real phase: 0.0
    width: bars * barWidth + Math.max(0, bars - 1) * gap
    height: maximumBarHeight
    spacing: gap

    Timer {
        running: root.mode !== "idle"
        repeat: true
        interval: 32
        onTriggered: {
            root.phase += 0.14
            // Smooth decay when no new level updates
            if (root.mode === "recording")
                root._smoothLevel = root._smoothLevel * 0.92
        }
    }

    Repeater {
        model: root.bars

        delegate: Rectangle {
            id: bar

            property real drive: {
                if (root.mode === "recording") {
                    // Per-bar variation: center bars taller, edges shorter
                    var centerWeight = 1.0 - Math.abs(index - (root.bars - 1) / 2.0) / ((root.bars - 1) / 2.0) * 0.35
                    // Subtle organic wave offset per bar
                    var wave = 0.88 + 0.12 * Math.sin(root.phase * 1.2 + index * 0.6)
                    // Apply compressed level with center weighting
                    return Math.pow(root._smoothLevel, 0.55) * centerWeight * wave
                }
                if (root.mode === "busy")
                    return 0.25 + 0.20 * Math.sin(root.phase * 0.9 + index * 0.45)
                if (root.mode === "error")
                    return 0.12 + 0.06 * Math.sin(root.phase * 1.6 + index * 0.7)
                // idle
                return 0.04 + 0.02 * Math.sin(root.phase * 0.4 + index * 0.35)
            }

            width: root.barWidth
            height: Math.max(root.minimumBarHeight,
                root.minimumBarHeight + drive * (root.maximumBarHeight - root.minimumBarHeight))
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter

            // Color intensity scales with level in recording mode
            color: {
                if (root.mode === "recording") {
                    var intensity = Math.min(1.0, root._smoothLevel * 1.3 + 0.3)
                    return Qt.rgba(
                        0.90 + 0.10 * intensity,
                        0.94 + 0.06 * intensity,
                        0.97,
                        0.5 + 0.5 * intensity
                    )
                }
                if (root.mode === "busy")
                    return theme.darkMode ? "#94A3B8" : "#7c8ba1"
                if (root.mode === "error")
                    return theme.error
                return theme.darkMode ? "#475569" : "#9aa9b7"
            }

            Behavior on height {
                NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
            }
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }
}
