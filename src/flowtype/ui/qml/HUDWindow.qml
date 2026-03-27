import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: hud

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
    readonly property int availableScreenWidth: Screen.desktopAvailableWidth > 0 ? Screen.desktopAvailableWidth : Screen.width
    readonly property int availableScreenHeight: Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : Screen.height

    width: lineIdle ? 32 : (compact ? (recording || busy || errorState ? 126 : 84) : (recording || busy || errorState ? 166 : 110))
    height: lineIdle ? 4 : (compact ? 32 : 40)
    x: Math.round((availableScreenWidth - width) / 2)
    y: Math.round(availableScreenHeight - height - (lineIdle ? 10 : 18))
    opacity: blockedByOnboarding ? 0 : ((recording || busy || errorState || idleHint) ? 1 : 0)

    function titleText() {
        if (recording)
            return "Listening"
        if (AppController.status === "transcribing")
            return "Transcribing"
        if (AppController.status === "cleaning")
            return "Cleaning"
        if (AppController.status === "pasting")
            return "Pasting"
        return "Ready"
    }

    function detailText() {
        if (recording)
            return "Release to finish"
        if (busy)
            return AppController.detail
        if (errorState)
            return AppController.detail
        return "Click or hold " + AppController.holdToTalk.toUpperCase().split("+").join(" + ") + " to start dictating"
    }

    function languageCode() {
        var code = AppController.transcriptionLanguage
        if (code === "auto")
            return "AUTO"
        return code.toUpperCase()
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
            if (AppController.status === "ready")
                hud.scheduleIdleHint()
            else {
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
        interval: 1500
        repeat: false
        onTriggered: hud.idlePreviewVisible = false
    }

    Timer {
        id: readyControlsTimer
        interval: 2200
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
        color: hud.lineIdle ? "#8e959c" : "#05090d"
        border.width: hud.lineIdle ? 0 : 1
        border.color: hud.recording ? "#5f402e" : (hud.errorState ? "#7c2d2d" : (hud.busy ? "#28415b" : "#25384a"))

        Rectangle {
            visible: !hud.lineIdle
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0d151f" }
                GradientStop { position: 1.0; color: "#081018" }
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
            width: Math.min(316, readyHintText.implicitWidth + 24)
            height: 32
            radius: 17
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 10
            color: "#05090d"
            border.width: 1
            border.color: "#24384b"

            Label {
                id: readyHintText
                anchors.centerIn: parent
                text: hud.detailText()
                color: "#f6f7fb"
                font.family: "Segoe UI Variable Text"
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        Row {
            visible: !hud.lineIdle
            anchors.centerIn: parent
            spacing: hud.compact ? 8 : 10

            Rectangle {
                id: languageButton
                visible: hud.readyControlsVisible || hud.recording || hud.busy
                width: 20
                height: 20
                radius: 11
                color: "#0b1219"
                border.width: 1
                border.color: "#294059"

                Label {
                    anchors.centerIn: parent
                    text: hud.languageCode()
                    color: "#f6f7fb"
                    font.family: "Bahnschrift SemiBold"
                    font.pixelSize: 8
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
                width: hud.compact ? 64 : 86
                height: hud.compact ? 18 : 22
                radius: height / 2
                color: "#04080c"
                border.width: 1
                border.color: hud.recording ? "#5a3b2e" : (hud.errorState ? "#7c2d2d" : (hud.busy ? "#294159" : "#203446"))

                WaveStrip {
                    anchors.centerIn: parent
                    bars: hud.compact ? 7 : 9
                    barWidth: hud.compact ? 3 : 4
                    gap: 3
                    minimumBarHeight: 3
                    maximumBarHeight: hud.compact ? 11 : 14
                    level: hud.displayedLevel
                    mode: hud.recording ? "recording" : (hud.errorState ? "error" : (hud.busy ? "busy" : "idle"))
                }
            }

            Rectangle {
                visible: hud.busy || hud.errorState
                width: 20
                height: 18
                radius: 10
                color: "#0b1219"
                border.width: 1
                border.color: hud.errorState ? "#7c2d2d" : "#294059"

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: 3

                        delegate: Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: hud.errorState ? "#fecaca" : "#eef4fb"
                            opacity: 0.3 + (0.7 * ((Math.sin(hud.phase * 1.7 + (index * 0.8)) + 1) / 2))
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: languagePopup

        parent: shell
        x: Math.max(10, (hud.width / 2) - (width / 2))
        y: -height - 10
        width: 218
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        padding: 8

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
            radius: 18
            color: "#ffffff"
            border.width: 1
            border.color: "#dce7ed"
        }

        contentItem: Column {
            spacing: 4

            Repeater {
                model: AppController.transcriptionLanguageCards

                delegate: Rectangle {
                    width: languagePopup.width - (languagePopup.padding * 2)
                    height: 42
                    radius: 14
                    color: AppController.transcriptionLanguage === modelData.code ? "#eef7f6" : "transparent"
                    border.width: AppController.transcriptionLanguage === modelData.code ? 1 : 0
                    border.color: "#b9e6de"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        spacing: 10

                        Label {
                            text: modelData.code === "auto" ? "AUTO" : modelData.code.toUpperCase()
                            color: "#7890a2"
                            font.family: "Bahnschrift SemiBold"
                            font.pixelSize: 11
                        }

                        Label {
                            text: modelData.label
                            color: "#173042"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 13
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
