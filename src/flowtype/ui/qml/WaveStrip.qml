import QtQuick

Item {
    id: root

    property real level: 0.0
    property string mode: "idle"
    property int bars: 16
    property int barWidth: 6
    property int minimumBarHeight: 5
    property int maximumBarHeight: 28
    property int gap: 4
    Theme { id: theme }

    property color activeColor: "#f8fafc"
    property color idleColor: "#7c8ba1"
    property real phase: 0.0

    implicitWidth: bars * barWidth + (bars - 1) * gap
    implicitHeight: maximumBarHeight

    function currentColor() {
        if (mode === "recording")
            return theme.tint(theme.primary, 0.98)
        if (mode === "busy")
            return theme.tint(theme.primary, 0.76)
        if (mode === "error")
            return theme.tint(theme.error, 0.9)
        return theme.tint("#9aa9b7", 0.9)
    }

    NumberAnimation on phase {
        from: 0
        to: 6.283
        duration: 1500
        loops: Animation.Infinite
        running: root.visible
    }

    Row {
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: root.bars

            delegate: Rectangle {
                property real baseLevel: root.mode === "recording"
                    ? Math.max(0.24 + (root.level * 0.9), 0.24)
                    : (root.mode === "busy" ? 0.34 : (root.mode === "error" ? 0.16 : 0.08))
                property real wobble: root.mode === "recording"
                    ? (0.42 + (0.58 * Math.sin(root.phase + (index * 0.48))))
                    : (0.55 + (0.45 * Math.sin(root.phase + (index * 0.45))))

                width: root.barWidth
                height: Math.max(root.minimumBarHeight, root.minimumBarHeight + (baseLevel * wobble * (root.maximumBarHeight - root.minimumBarHeight)))
                radius: width / 2
                color: root.currentColor()

                Behavior on height {
                    NumberAnimation {
                        duration: root.mode === "recording" ? 90 : 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
