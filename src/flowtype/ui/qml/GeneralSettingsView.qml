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
        maxContentWidth: 1060
        contentSpacing: theme.sectionGap

        // ── Header Actions ───────────────────────────────
        Item {
            width: parent.width
            height: headLabel.implicitHeight

            Label {
                id: headLabel
                text: "General Settings"
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizePageTitle
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── Shortcuts ────────────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Shortcuts"
                    subtitle: "Click a row, press the full combination to record it. Applies immediately."
                    
                    FlowButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Load Defaults"
                        variant: "secondary"
                        compact: true
                        onClicked: AppController.restoreRecommendedShortcuts()
                    }
                }

                Repeater {
                    model: [
                        { "title": "Push to talk",     "detail": "Hold to record, release to stop.", "key": "hold_to_talk",     "shortcut": AppController.holdToTalk,             "requireModifier": true,  "idleText": "Click here, then press Ctrl + Shift + Space" },
                        { "title": "Toggle recording", "detail": "Tap once to start, tap again to stop.", "key": "toggle_recording", "shortcut": AppController.toggleRecordingShortcut, "requireModifier": true,  "idleText": "Click here, then press a modifier shortcut" },
                        { "title": "Cancel recording", "detail": "Discard the current dictation immediately.", "key": "cancel_recording", "shortcut": AppController.cancelRecording,       "requireModifier": false, "idleText": "Click here, then press Esc" },
                        { "title": "Re-paste last",    "detail": "Send the most recent cleaned text again.", "key": "repaste_last",     "shortcut": AppController.repasteLast,             "requireModifier": true,  "idleText": "Click here..." }
                    ]

                    delegate: Column {
                        width: parent.width
                        spacing: theme.space8

                        Rectangle { width: parent.width; height: 1; color: theme.divider; visible: index > 0 }

                        FormRow {
                            width: parent.width
                            title: modelData.title
                            subtitle: modelData.detail

                            RowLayout {
                                spacing: theme.space8

                                ShortcutRecorder {
                                    Layout.preferredWidth: 320
                                    shortcut: modelData.shortcut
                                    actionName: modelData.key
                                    isRecording: AppController.isRecordingShortcut && AppController.recordingShortcutAction === modelData.key
                                    onShortcutRecorded: (newShortcut) => AppController.saveShortcut(modelData.key, newShortcut)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Transcription Language ───────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Transcription Language"
                    subtitle: "Locking the model to one language improves transcription speed and reduces hallucinations."
                }

                GridLayout {
                    width: parent.width
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
                            onClicked: {
                                root.languageDraft = modelData.code
                                AppController.saveTranscriptionLanguage(modelData.code)
                            }
                        }
                    }
                }
            }
        }

        // ── System Behavior ──────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "System Behavior"
                    subtitle: "Control how FlowType runs in the background."
                    
                    FlowButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Apply"
                        variant: "secondary"
                        compact: true
                        onClicked: AppController.saveStartupSettings(root.launchAtLoginDraft, root.startMinimizedDraft, root.closeToTrayDraft)
                    }
                }

                Repeater {
                    model: [
                        { "title": "Launch at login",       "detail": "Automatically start FlowType when Windows boots up." },
                        { "title": "Start minimized", "detail": "Open in the system tray instead of showing the main window on launch." },
                        { "title": "Close to tray",         "detail": "Clicking the window close button minimizes exactly like a system utility." }
                    ]

                    delegate: Column {
                        width: parent.width
                        spacing: theme.space8

                        Rectangle { width: parent.width; height: 1; color: theme.divider; visible: index > 0 }

                        FormRow {
                            width: parent.width
                            title: modelData.title
                            subtitle: modelData.detail

                            FlowSwitch {
                                checked: index === 0 ? root.launchAtLoginDraft : (index === 1 ? root.startMinimizedDraft : root.closeToTrayDraft)
                                onClicked: {
                                    if (index === 0) root.launchAtLoginDraft = checked
                                    else if (index === 1) root.startMinimizedDraft = checked
                                    else root.closeToTrayDraft = checked
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Developer / Data ─────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Local Application Data"
                    subtitle: "Quickly access underlying directories and logs for debugging."
                }

                Row {
                    spacing: theme.space12

                    FlowButton {
                        label: "App Data Folder"
                        variant: "secondary"
                        onClicked: AppController.openAppDirectory()
                    }

                    FlowButton {
                        label: "Log Directory"
                        variant: "secondary"
                        onClicked: AppController.openLogsDirectory()
                    }

                    FlowButton {
                        label: "Raw Config File"
                        variant: "secondary"
                        onClicked: AppController.openConfigFile()
                    }
                }
            }
        }
    }
}
