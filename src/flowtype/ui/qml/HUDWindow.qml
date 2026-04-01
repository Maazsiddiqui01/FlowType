import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: hudWindow

    Theme { id: theme }

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowTransparentForInput
    color: "transparent"
    visible: true

    property string hudStyle: AppController.hudStyle
    property string hudPosition: AppController.hudPosition
    property bool showIdleHud: AppController.showIdleHud
    property bool isRecording: AppController.status === "recording"
    property bool isBusy: AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting"
    property bool isError: AppController.status === "error"
    property bool isReady: AppController.status === "ready"
    property bool shouldShow: isRecording || isBusy || isError || (isReady && showIdleHud)

    width: hudStyle === "mini" ? 136 : 176
    height: hudStyle === "mini" ? 40 : 48

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
        if (isError) return "error"
        if (isBusy) return "busy"
        return "idle"
    }

    // ── HUD pill ─────────────────────────────────────────
    Rectangle {
        id: hudPill
        anchors.centerIn: parent
        width: hudWindow.width
        height: hudWindow.height
        radius: height / 2
        color: theme.darkMode ? "#0A0E16" : "#0C1622"
        border.width: 1
        border.color: theme.darkMode ? "#1A2538" : "#243446"
        opacity: hudWindow.shouldShow ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

        // Recording glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(0.42, 0.55, 1.0, hudWindow.isRecording ? 0.25 * (0.5 + 0.5 * Math.sin(glowPhase.phase)) : 0)
            visible: hudWindow.isRecording

            property QtObject glowPhase: QtObject {
                property real phase: 0.0
                property bool running: hudWindow.isRecording
            }

            Timer {
                running: parent.visible
                repeat: true
                interval: 30
                onTriggered: parent.glowPhase.phase += 0.08
            }

            Behavior on border.color { ColorAnimation { duration: 300 } }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            // Language badge
            Rectangle {
                visible: hudWindow.showIdleHud || !hudWindow.isReady
                width: 20
                height: 20
                radius: 10
                color: theme.darkMode ? "#0C1622" : "#0A0E16"
                border.width: 1
                border.color: theme.darkMode ? "#1E3048" : "#233447"
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    anchors.centerIn: parent
                    text: AppController.transcriptionLanguage === "auto"
                        ? "A"
                        : AppController.transcriptionLanguage.toUpperCase().slice(0, 2)
                    color: "#F0F4F8"
                    font.family: theme.fontUi
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            // Waveform
            WaveStrip {
                anchors.verticalCenter: parent.verticalCenter
                bars: hudWindow.hudStyle === "mini" ? 7 : 9
                barWidth: 4
                gap: 4
                minimumBarHeight: 3
                maximumBarHeight: hudWindow.hudStyle === "mini" ? 14 : 20
                level: AppController.audioLevel
                mode: hudWindow.waveMode()
            }
        }
    }
}
