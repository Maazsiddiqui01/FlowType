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
    property color activeColor: "#f8fafc"
    property color idleColor: "#7c8ba1"
    property real phase: 0.0

    implicitWidth: bars * barWidth + (bars - 1) * gap
    implicitHeight: maximumBarHeight

    function currentColor() {
        if (mode === "recording")
            return activeColor
        if (mode === "busy")
            return "#c6daff"
        if (mode === "error")
            return "#fda4af"
        return idleColor
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
                property real baseLevel: root.mode === "recording" ? Math.max(root.level * 1.6, 0.06) : (root.mode === "busy" ? 0.28 : (root.mode === "error" ? 0.16 : 0.04))
                property real wobble: 0.55 + (0.45 * Math.sin(root.phase + (index * 0.45)))

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
