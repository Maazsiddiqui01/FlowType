import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string languageDraft: AppController.transcriptionLanguage
    property bool launchAtLoginDraft: AppController.launchAtLogin
    property bool startMinimizedDraft: AppController.startMinimized
    property bool closeToTrayDraft: AppController.closeToTray

    Connections {
        target: AppController

        function onConfigChanged() {
            root.languageDraft = AppController.transcriptionLanguage
            root.launchAtLoginDraft = AppController.launchAtLogin
            root.startMinimizedDraft = AppController.startMinimized
            root.closeToTrayDraft = AppController.closeToTray
        }
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1220
        contentSpacing: 18

        SurfacePanel {
            width: parent.width
            accent: "#0d9488"
            cornerRadius: 24
            padding: 22

            Column {
                width: parent.width
                spacing: 12

                Label {
                    text: "Shortcuts"
                    color: "#163042"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 24
                    font.weight: Font.Black
                }

                Label {
                    width: parent.width
                    text: "Click a row, press the full combination, and FlowType reloads the runtime immediately. Toggle recording is better for long dictation."
                    color: "#627b8e"
                    font.family: "Segoe UI Variable Text"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    width: parent.width
                    spacing: 10

                    FlowButton {
                        label: "Use Recommended Defaults"
                        variant: "secondary"
                        compact: true
                        onClicked: AppController.restoreRecommendedShortcuts()
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Default setup: hold `Ctrl + Shift + Space`, toggle `Ctrl + Alt + Space`, cancel `Esc`."
                        color: "#72879a"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                }

                Repeater {
                    model: [
                        { "title": "Push to talk", "detail": "Hold to record and release when done.", "key": "hold_to_talk", "shortcut": AppController.holdToTalk, "requireModifier": true, "idleText": "Click, then press Ctrl + Shift + Space" },
                        { "title": "Toggle recording", "detail": "Tap once to start and again to stop.", "key": "toggle_recording", "shortcut": AppController.toggleRecordingShortcut, "requireModifier": true, "idleText": "Click, then press a modified shortcut" },
                        { "title": "Cancel recording", "detail": "Discard the current take immediately.", "key": "cancel_recording", "shortcut": AppController.cancelRecording, "requireModifier": false, "idleText": "Click, then press Esc or a modified key" },
                        { "title": "Re-paste last", "detail": "Send the most recent cleaned text again.", "key": "repaste_last", "shortcut": AppController.repasteLast, "requireModifier": true, "idleText": "Click, then press a safe modified shortcut" }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 84
                        radius: 18
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#dce7ed"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: modelData.title
                                    color: "#173042"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    text: modelData.detail
                                    color: "#627b8e"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            ShortcutRecorder {
                                Layout.preferredWidth: 360
                                Layout.maximumWidth: 420
                                currentShortcut: modelData.shortcut
                                requireModifier: modelData.requireModifier
                                idleText: modelData.idleText
                                onShortcutRecorded: (newShortcut) => AppController.saveShortcut(modelData.key, newShortcut)
                            }

                            FlowButton {
                                label: "Clear"
                                variant: "secondary"
                                compact: true
                                buttonEnabled: modelData.shortcut.length > 0
                                onClicked: AppController.saveShortcut(modelData.key, "")
                            }
                        }
                    }
                }
            }
        }

        SurfacePanel {
            width: parent.width
            accent: "#10b981"
            cornerRadius: 24
            padding: 22

            Column {
                width: parent.width
                spacing: 14

                RowLayout {
                    width: parent.width

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Transcription language"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 24
                            font.weight: Font.Black
                        }

                        Label {
                            text: "Lock Whisper to one language for better speed and fewer bad guesses. Use auto detect only if you genuinely switch languages."
                            color: "#627b8e"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    FlowButton {
                        label: "Save Language"
                        variant: "success"
                        onClicked: AppController.saveTranscriptionLanguage(root.languageDraft)
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: AppController.transcriptionLanguageCards

                        delegate: Rectangle {
                            width: Math.min((parent.width - 24) / 3, 300)
                            height: 94
                            radius: 18
                            color: root.languageDraft === modelData.code ? Qt.rgba(16 / 255, 185 / 255, 129 / 255, 0.12) : "#ffffff"
                            border.width: 1
                            border.color: root.languageDraft === modelData.code ? "#72d8c1" : "#dce7ed"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 6

                                Label {
                                    text: modelData.label
                                    color: "#173042"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    width: parent.width
                                    text: modelData.summary
                                    color: "#627b8e"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.languageDraft = modelData.code
                            }
                        }
                    }
                }
            }
        }

        SurfacePanel {
            width: parent.width
            accent: "#6366f1"
            cornerRadius: 24
            padding: 22

            Column {
                width: parent.width
                spacing: 14

                RowLayout {
                    width: parent.width

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Background behavior"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 24
                            font.weight: Font.Black
                        }

                        Label {
                            text: "These settings control how FlowType behaves like a normal Windows utility: startup, tray persistence, and whether login launches stay out of the way."
                            color: "#627b8e"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    FlowButton {
                        label: "Save Background Behavior"
                        variant: "secondary"
                        onClicked: AppController.saveStartupSettings(root.launchAtLoginDraft, root.startMinimizedDraft, root.closeToTrayDraft)
                    }
                }

                Repeater {
                    model: [
                        {
                            "title": "Launch at login",
                            "detail": "Recommended for daily use so global hotkeys are ready right after Windows signs in."
                        },
                        {
                            "title": "Start minimized to tray",
                            "detail": "When login startup is enabled, open in the tray instead of dropping the full window on screen."
                        },
                        {
                            "title": "Close window to tray",
                            "detail": "The close button keeps FlowType alive in the background until you quit from the tray menu."
                        }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 82
                        radius: 18
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#dce7ed"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: modelData.title
                                    color: "#173042"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.detail
                                    color: "#627b8e"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                }
                            }

                            FlowSwitch {
                                checked: index === 0
                                    ? root.launchAtLoginDraft
                                    : (index === 1 ? root.startMinimizedDraft : root.closeToTrayDraft)
                                onToggled: (checked) => {
                                    if (index === 0)
                                        root.launchAtLoginDraft = checked
                                    else if (index === 1)
                                        root.startMinimizedDraft = checked
                                    else
                                        root.closeToTrayDraft = checked
                                }
                            }
                        }
                    }
                }
            }
        }

        SurfacePanel {
            width: parent.width
            accent: "#2563eb"
            cornerRadius: 24
            padding: 22

            Column {
                width: parent.width
                spacing: 12

                Label {
                    text: "Local actions"
                    color: "#163042"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 24
                    font.weight: Font.Black
                }

                Row {
                    spacing: 12

                    FlowButton {
                        label: "Open App Folder"
                        variant: "secondary"
                        onClicked: AppController.openAppDirectory()
                    }

                    FlowButton {
                        label: "Open Logs"
                        variant: "secondary"
                        onClicked: AppController.openLogsDirectory()
                    }

                    FlowButton {
                        label: "Open Config"
                        variant: "secondary"
                        onClicked: AppController.openConfigFile()
                    }
                }
            }
        }
    }
}
