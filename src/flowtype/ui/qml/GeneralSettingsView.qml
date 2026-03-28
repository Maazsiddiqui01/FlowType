import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

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
        maxContentWidth: 1240
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Shortcuts"
                subtitle: "Click a row, press the full combination, and FlowType reloads the runtime immediately."

                trailing: FlowButton {
                    label: "Use Recommended Defaults"
                    variant: "secondary"
                    compact: true
                    onClicked: AppController.restoreRecommendedShortcuts()
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 74
                spacing: theme.space12

                Repeater {
                    model: [
                        { "title": "Push to talk", "detail": "Hold to record and release when done.", "key": "hold_to_talk", "shortcut": AppController.holdToTalk, "requireModifier": true, "idleText": "Click, then press Ctrl + Shift + Space" },
                        { "title": "Toggle recording", "detail": "Tap once to start and again to stop.", "key": "toggle_recording", "shortcut": AppController.toggleRecordingShortcut, "requireModifier": true, "idleText": "Click, then press a modified shortcut" },
                        { "title": "Cancel recording", "detail": "Discard the current take immediately.", "key": "cancel_recording", "shortcut": AppController.cancelRecording, "requireModifier": false, "idleText": "Click, then press Esc or a modified key" },
                        { "title": "Re-paste last", "detail": "Send the most recent cleaned text again.", "key": "repaste_last", "shortcut": AppController.repasteLast, "requireModifier": true, "idleText": "Click, then press a safe modified shortcut" }
                    ]

                    delegate: FormRow {
                        width: parent.width
                        title: modelData.title
                        detail: modelData.detail

                        ShortcutRecorder {
                            Layout.preferredWidth: 304
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

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Transcription language"
                subtitle: "Lock Whisper to one language for better speed and fewer bad guesses."

                trailing: FlowButton {
                    label: "Save Language"
                    variant: "success"
                    onClicked: AppController.saveTranscriptionLanguage(root.languageDraft)
                }
            }

            GridLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 74
                columns: 4
                columnSpacing: theme.space12
                rowSpacing: theme.space12

                Repeater {
                    model: AppController.transcriptionLanguageCards

                    delegate: ChoiceCard {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        title: modelData.label
                        subtitle: modelData.summary
                        selected: root.languageDraft === modelData.code
                        accent: theme.teal
                        onClicked: root.languageDraft = modelData.code
                    }
                }
            }
        }

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Background behavior"
                subtitle: "These settings control how FlowType behaves like a normal Windows utility."

                trailing: FlowButton {
                    label: "Save Background Behavior"
                    variant: "secondary"
                    onClicked: AppController.saveStartupSettings(root.launchAtLoginDraft, root.startMinimizedDraft, root.closeToTrayDraft)
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 74
                spacing: theme.space12

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

                    delegate: FormRow {
                        width: parent.width
                        title: modelData.title
                        detail: modelData.detail

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

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Local actions"
                subtitle: "Open the app folder, logs, or config file without leaving FlowType."
            }

            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 74
                spacing: theme.space8

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
