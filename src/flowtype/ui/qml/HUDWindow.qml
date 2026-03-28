import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: hud

    Theme { id: theme }

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    color: "transparent"
    visible: opacity > 0.01

    property bool recording: AppController.status === "recording"
    property bool busy: AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting"
    property bool errorState: AppController.status === "error"
    property bool compact: AppController.hudStyle === "mini"
    property bool idlePreviewVisible: false
    property bool readyControlsVisible: false
    property real displayedLevel: AppController.audioLevel
    property real phase: 0
    readonly property bool blockedByOnboarding: AppController.onboardingVisible
    readonly property bool idleHint: AppController.status === "ready" && (idlePreviewVisible || readyControlsVisible || languagePopup.visible)
    readonly property bool lineIdle: idleHint && !recording && !busy && !errorState && !readyControlsVisible && !languagePopup.visible
    readonly property bool topDocked: AppController.hudPosition === "top"

    width: lineIdle ? 28 : (compact ? (recording || busy || errorState ? 146 : 92) : (recording || busy || errorState ? 186 : 114))
    height: lineIdle ? 4 : (compact ? 36 : 42)
    opacity: blockedByOnboarding ? 0 : ((recording || busy || errorState || idleHint) ? 1 : 0)

    function detailText() {
        if (recording)
            return "Listening"
        if (AppController.status === "transcribing")
            return "Transcribing"
        if (AppController.status === "cleaning")
            return "Polishing transcript"
        if (AppController.status === "pasting")
            return "Pasting"
        if (errorState)
            return AppController.detail
        return "Hold " + AppController.holdToTalk.toUpperCase().split("+").join(" + ") + " to start dictating"
    }

    function languageCode() {
        var code = AppController.transcriptionLanguage
        if (code === "auto")
            return "A"
        return code.toUpperCase().slice(0, 2)
    }

    function scheduleIdleHint() {
        if (blockedByOnboarding || !AppController.showIdleHud || AppController.status !== "ready")
            return
        idlePreviewVisible = true
        idleHintTimer.restart()
    }

    function showReadyControls() {
        if (blockedByOnboarding || AppController.status !== "ready")
            return
        readyControlsVisible = true
        idlePreviewVisible = false
        readyControlsTimer.restart()
    }

    function collapseReadyControls() {
        if (languagePopup.visible)
            return
        readyControlsVisible = false
        if (AppController.showIdleHud && AppController.status === "ready")
            scheduleIdleHint()
    }

    Component.onCompleted: scheduleIdleHint()

    Connections {
        target: AppController

        function onStateChanged() {
            if (AppController.status === "ready") {
                hud.scheduleIdleHint()
            } else {
                hud.idlePreviewVisible = false
                hud.readyControlsVisible = false
                idleHintTimer.stop()
                readyControlsTimer.stop()
                if (languagePopup.visible)
                    languagePopup.close()
            }
        }

        function onConfigChanged() {
            if (hud.blockedByOnboarding || !AppController.showIdleHud) {
                hud.idlePreviewVisible = false
                hud.readyControlsVisible = false
                idleHintTimer.stop()
                readyControlsTimer.stop()
                if (languagePopup.visible)
                    languagePopup.close()
            } else if (AppController.status === "ready" && !hud.readyControlsVisible) {
                hud.scheduleIdleHint()
            }
        }
    }

    Timer {
        id: idleHintTimer
        interval: 1600
        repeat: false
        onTriggered: hud.idlePreviewVisible = false
    }

    Timer {
        id: readyControlsTimer
        interval: 2400
        repeat: false
        onTriggered: hud.collapseReadyControls()
    }

    NumberAnimation on phase {
        from: 0
        to: 6.283
        duration: 1300
        loops: Animation.Infinite
        running: hud.opacity > 0
    }

    Behavior on displayedLevel { SmoothedAnimation { duration: 90 } }
    Behavior on opacity { NumberAnimation { duration: 160 } }
    Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

    Rectangle {
        id: shell
        anchors.fill: parent
        radius: hud.lineIdle ? 2 : height / 2
        color: hud.lineIdle ? theme.textTertiary : theme.inkDark
        border.width: hud.lineIdle ? 0 : 1
        border.color: hud.recording
            ? theme.tint(theme.warm, 0.42)
            : (hud.errorState
                ? theme.tint(theme.error, 0.45)
                : (hud.busy
                    ? theme.tint(theme.primary, 0.35)
                    : Qt.rgba(1, 1, 1, 0.08)))

        Rectangle {
            visible: !hud.lineIdle
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#09111A" }
                GradientStop { position: 1.0; color: "#060D15" }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (hud.lineIdle || (!hud.recording && !hud.busy && !hud.errorState))
                    hud.showReadyControls()
            }
            onEntered: {
                if (hud.lineIdle)
                    hud.showReadyControls()
            }
        }

        Rectangle {
            visible: hud.readyControlsVisible && !hud.recording && !hud.busy && !hud.errorState && !languagePopup.visible
            width: Math.min(360, readyHintText.implicitWidth + 24)
            height: 34
            radius: 17
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 10
            color: theme.inkDark
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)

            Label {
                id: readyHintText
                anchors.centerIn: parent
                text: hud.detailText()
                color: "#F7FAFC"
                font.family: theme.fontUi
                font.pixelSize: theme.textLabel
                font.weight: Font.DemiBold
            }
        }

        Row {
            visible: !hud.lineIdle
            anchors.centerIn: parent
            spacing: compact ? 8 : 10

            Rectangle {
                visible: hud.readyControlsVisible || hud.recording || hud.busy
                width: 20
                height: 20
                radius: 10
                color: "#0C1622"
                border.width: 1
                border.color: "#243446"

                Label {
                    anchors.centerIn: parent
                    text: hud.languageCode()
                    color: "#F7FAFC"
                    font.family: theme.fontUi
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        hud.readyControlsVisible = true
                        idleHintTimer.stop()
                        readyControlsTimer.stop()
                        if (languagePopup.visible)
                            languagePopup.close()
                        else
                            languagePopup.open()
                    }
                }
            }

            Rectangle {
                width: hud.compact ? 70 : 92
                height: hud.compact ? 20 : 24
                radius: height / 2
                color: "#04080C"
                border.width: 1
                border.color: hud.recording
                    ? theme.tint(theme.warm, 0.4)
                    : (hud.errorState
                        ? theme.tint(theme.error, 0.4)
                        : (hud.busy
                            ? theme.tint(theme.primary, 0.32)
                            : "#1C2A38"))

                WaveStrip {
                    anchors.centerIn: parent
                    bars: hud.compact ? 7 : 9
                    barWidth: hud.compact ? 4 : 4
                    gap: 4
                    minimumBarHeight: 4
                    maximumBarHeight: hud.compact ? 12 : 16
                    level: hud.displayedLevel
                    mode: hud.recording ? "recording" : (hud.errorState ? "error" : (hud.busy ? "busy" : "idle"))
                }
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: "#0C1622"
                border.width: 1
                border.color: hud.errorState
                    ? theme.tint(theme.error, 0.42)
                    : (hud.recording
                        ? theme.tint(theme.warm, 0.42)
                        : theme.tint(theme.primary, 0.28))
                visible: hud.recording || hud.busy || hud.errorState

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: hud.busy ? busyDots : stateDot
                }
            }
        }
    }

    Component {
        id: stateDot

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: hud.errorState ? theme.error : (hud.recording ? theme.warm : theme.primary)
            opacity: hud.recording ? (0.45 + (0.55 * ((Math.sin(hud.phase * 1.8) + 1) / 2))) : 1
        }
    }

    Component {
        id: busyDots

        Row {
            spacing: 3

            Repeater {
                model: 3

                delegate: Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: "#F2F6FB"
                    opacity: 0.3 + (0.7 * ((Math.sin(hud.phase * 1.7 + (index * 0.8)) + 1) / 2))
                }
            }
        }
    }

    Popup {
        id: languagePopup

        parent: shell
        x: Math.max(10, (hud.width / 2) - (width / 2))
        y: -height - 10
        width: 212
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        padding: theme.space8

        onOpened: {
            hud.readyControlsVisible = true
            idleHintTimer.stop()
            readyControlsTimer.stop()
        }

        onClosed: {
            if (AppController.status === "ready")
                readyControlsTimer.restart()
        }

        background: Rectangle {
            radius: theme.radiusCard
            color: theme.surface
            border.width: 1
            border.color: theme.border
        }

        contentItem: Column {
            spacing: theme.space4

            Repeater {
                model: AppController.transcriptionLanguageCards

                delegate: Rectangle {
                    width: languagePopup.width - (languagePopup.padding * 2)
                    height: 40
                    radius: theme.radiusControl
                    color: AppController.transcriptionLanguage === modelData.code
                        ? theme.tint(theme.teal, 0.08)
                        : "transparent"
                    border.width: AppController.transcriptionLanguage === modelData.code ? 1 : 0
                    border.color: theme.tint(theme.teal, 0.24)

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 10

                        Label {
                            text: modelData.code === "auto" ? "A" : modelData.code.toUpperCase()
                            color: theme.textTertiary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textLabel
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: modelData.label
                            color: theme.textPrimary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textBody
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AppController.saveTranscriptionLanguage(modelData.code)
                            languagePopup.close()
                        }
                    }
                }
            }
        }
    }
}
