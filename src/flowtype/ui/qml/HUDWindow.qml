import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: hudWindow

    Theme { id: theme }

    // Hover-aware but never steals keyboard focus (WS_EX_NOACTIVATE), so dictation
    // still pastes into the app you're typing in. Not TransparentForInput, so the
    // idle line can detect hover and expand -- like Wispr Flow.
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    color: "transparent"
    visible: shouldShow

    property string status: AppController.status
    property bool isRecording: status === "recording"
    property bool isBusy: status === "transcribing" || status === "cleaning" || status === "pasting"
    property bool isError: status === "error"
    property bool isReady: status === "ready" || status === "starting"
    property bool showIdleHud: AppController.showIdleHud
    property bool active: isRecording || isBusy || isError
    property bool hovered: hoverArea.containsMouse || (typeof HudForceHover !== "undefined" && HudForceHover)
    property bool expanded: active || hovered
    // The idle line is always present (unless disabled); it expands on hover/activity.
    property bool shouldShow: (active || (isReady && showIdleHud)) && !AppController.resultCardVisible

    readonly property int idleWidth: 66
    readonly property int idleHeight: 16
    readonly property int expandedHeight: 38

    width: Math.round(expanded ? Math.max(132, contentRow.implicitWidth + 30) : idleWidth)
    height: expanded ? expandedHeight : idleHeight

    Behavior on width { NumberAnimation { duration: theme.durBase; easing.type: theme.easeOut } }
    Behavior on height { NumberAnimation { duration: theme.durBase; easing.type: theme.easeOut } }

    Connections {
        target: AppController
        function onConfigChanged() { hudWindow.showIdleHud = AppController.showIdleHud }
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
        if (status === "transcribing") return "Transcribing"
        if (status === "cleaning") return "Polishing"
        if (status === "pasting") return "Pasting"
        if (isError) return "Error"
        return "Ready"
    }

    function shortcutKeys() {
        var raw = AppController.holdToTalk || "ctrl+shift+space"
        var parts = raw.split("+")
        var out = []
        for (var i = 0; i < parts.length; i += 1) {
            var p = parts[i].trim()
            if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.slice(1))
        }
        return out.join(" + ")
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // ── The capsule ──────────────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: hudWindow.expanded ? theme.hudFill
            : (theme.darkMode ? Qt.rgba(0.05, 0.07, 0.11, 0.72) : Qt.rgba(0.07, 0.10, 0.16, 0.62))
        border.width: 1
        border.color: theme.hudBorder
        opacity: hudWindow.shouldShow ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: theme.durBase; easing.type: theme.easeInOut } }
        Behavior on color { ColorAnimation { duration: theme.durBase } }

        // top sheen
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 0.6; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
            }
        }

        // recording halo
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.width: 2
            border.color: theme.tint(theme.warm, hudWindow.isRecording ? 0.30 * (0.5 + 0.5 * Math.sin(glow.phase)) : 0)
            visible: hudWindow.isRecording
            property QtObject glow: QtObject { property real phase: 0.0 }
            Timer { running: parent.visible; repeat: true; interval: 30; onTriggered: parent.glow.phase += 0.08 }
        }

        // ── Idle: a tiny blank line ──────────────────────────────────────────
        Rectangle {
            visible: !hudWindow.expanded
            anchors.centerIn: parent
            width: 40
            height: 4
            radius: 2
            color: theme.darkMode ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(1, 1, 1, 0.55)
        }

        // ── Expanded: hint (hover) or waveform (active) ──────────────────────
        RowLayout {
            id: contentRow
            visible: hudWindow.expanded
            anchors.centerIn: parent
            spacing: 9

            // State dot (active) — recording/busy/error
            Rectangle {
                visible: hudWindow.active
                Layout.alignment: Qt.AlignVCenter
                width: 8; height: 8; radius: 4
                color: hudWindow.stateColor()
                Behavior on color { ColorAnimation { duration: theme.durBase } }
            }

            WaveStrip {
                visible: hudWindow.active
                Layout.alignment: Qt.AlignVCenter
                bars: 6
                barWidth: 2
                gap: 2
                minimumBarHeight: 2
                maximumBarHeight: 12
                level: AppController.audioLevel
                mode: hudWindow.waveMode()
            }

            Label {
                visible: hudWindow.active
                Layout.alignment: Qt.AlignVCenter
                text: hudWindow.stateLabel()
                color: theme.hudText
                font.family: theme.fontUi
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            // Hover (idle): "Dictate  Ctrl + Shift + Space"
            Label {
                visible: !hudWindow.active
                Layout.alignment: Qt.AlignVCenter
                text: "Dictate"
                color: theme.hudText
                font.family: theme.fontUi
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Label {
                visible: !hudWindow.active
                Layout.alignment: Qt.AlignVCenter
                text: hudWindow.shortcutKeys()
                color: theme.primary
                font.family: theme.fontUi
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }
    }
}
