import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: hudWindow

    Theme { id: theme }

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowTransparentForInput
    color: "transparent"
    visible: shouldShow

    property string hudStyle: AppController.hudStyle
    property string hudPosition: AppController.hudPosition
    property bool showIdleHud: AppController.showIdleHud
    property bool isRecording: AppController.status === "recording"
    property bool isBusy: AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting"
    property bool isError: AppController.status === "error"
    property bool isReady: AppController.status === "ready"
    // Hide while the result card is up so the two overlays never stack on the same anchor.
    property bool shouldShow: (isRecording || isBusy || isError || (isReady && showIdleHud))
        && !AppController.resultCardVisible

    readonly property int hPad: 16
    readonly property int hudHeight: hudStyle === "mini" ? 40 : 46
    width: Math.round(Math.max(96, contentRow.implicitWidth + hPad * 2))
    height: hudHeight

    Connections {
        target: AppController
        function onConfigChanged() {
            hudWindow.hudStyle = AppController.hudStyle
            hudWindow.hudPosition = AppController.hudPosition
            hudWindow.showIdleHud = AppController.showIdleHud
        }
    }

    function waveMode() {
        if (isRecording) return "recording"
        if (isBusy) return "busy"
        return "idle"
    }

    function stateColor() {
        if (isRecording) return theme.warm
        if (isBusy) return theme.primary
        if (isError) return theme.error
        return theme.success
    }

    function stateLabel() {
        if (isRecording) return "Recording"
        if (AppController.status === "transcribing") return "Transcribing"
        if (AppController.status === "cleaning") return "Polishing"
        if (AppController.status === "pasting") return "Pasting"
        if (isError) return "Error"
        return "Ready"
    }

    // ── Frosted HUD pill ─────────────────────────────────────────────────────
    Rectangle {
        id: hudPill
        anchors.fill: parent
        radius: height / 2
        color: theme.hudFill
        border.width: 1
        border.color: theme.hudBorder
        opacity: hudWindow.shouldShow ? 1.0 : 0.0
        visible: opacity > 0
        antialiasing: true

        Behavior on opacity { NumberAnimation { duration: theme.durBase; easing.type: theme.easeInOut } }

        // Top frost sheen
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.12) }
            }
        }

        // Soft recording halo
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 2
            border.color: theme.tint(theme.warm, hudWindow.isRecording ? 0.30 * (0.5 + 0.5 * Math.sin(glow.phase)) : 0)
            visible: hudWindow.isRecording

            property QtObject glow: QtObject { property real phase: 0.0 }

            Timer {
                running: parent.visible
                repeat: true
                interval: 30
                onTriggered: parent.glow.phase += 0.08
            }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 9

            // State dot
            Rectangle {
                id: stateDot
                Layout.alignment: Qt.AlignVCenter
                width: 9
                height: 9
                radius: 4.5
                color: hudWindow.stateColor()
                Behavior on color { ColorAnimation { duration: theme.durBase } }

                // gentle pulse while busy
                SequentialAnimation on opacity {
                    id: busyPulse
                    running: hudWindow.isBusy
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.35; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.35; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                    onRunningChanged: if (!running) stateDot.opacity = 1.0
                }
            }

            // Waveform (recording + busy share the animated strip)
            WaveStrip {
                Layout.alignment: Qt.AlignVCenter
                visible: hudWindow.isRecording || hudWindow.isBusy
                bars: hudWindow.hudStyle === "mini" ? 6 : 8
                barWidth: 3
                gap: 3
                minimumBarHeight: 3
                maximumBarHeight: hudWindow.hudStyle === "mini" ? 12 : 16
                level: AppController.audioLevel
                mode: hudWindow.waveMode()
            }

            // Status word
            Label {
                Layout.alignment: Qt.AlignVCenter
                text: hudWindow.stateLabel()
                color: theme.hudText
                font.family: theme.fontUi
                font.pixelSize: hudWindow.hudStyle === "mini" ? 11 : 12
                font.weight: Font.DemiBold
            }
        }
    }
}
