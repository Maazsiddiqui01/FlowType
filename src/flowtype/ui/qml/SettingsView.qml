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
        maxContentWidth: 1180
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            ColumnLayout {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Shortcuts"
                    subtitle: "These apply immediately after saving, so the app stays predictable everywhere."

                    trailing: FlowButton {
                        label: "Load Defaults"
                        variant: "secondary"
                        onClicked: AppController.restoreRecommendedShortcuts()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.space12

                    Repeater {
                        model: [
                            { "title": "Push to talk", "detail": "Hold to record and release to stop.", "key": "hold_to_talk", "shortcut": AppController.holdToTalk },
                            { "title": "Toggle recording", "detail": "Tap once to start and again to stop.", "key": "toggle_recording", "shortcut": AppController.toggleRecordingShortcut },
                            { "title": "Cancel recording", "detail": "Discard the current take immediately.", "key": "cancel_recording", "shortcut": AppController.cancelRecording },
                            { "title": "Re-paste last", "detail": "Send the most recent cleaned text again.", "key": "repaste_last", "shortcut": AppController.repasteLast }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 74
                            radius: theme.radiusCard
                            color: theme.surfaceSubtle
                            border.width: 1
                            border.color: theme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: theme.space12
                                spacing: theme.space16

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: modelData.title
                                        color: theme.textPrimary
                                        font.family: theme.fontText
                                        font.pixelSize: theme.sizeCardTitle
                                        font.weight: 650
                                    }

                                    Label {
                                        text: modelData.detail
                                        color: theme.textSecondary
                                        font.family: theme.fontText
                                        font.pixelSize: theme.sizeHelper
                                    }
                                }

                                ShortcutRecorder {
                                    Layout.preferredWidth: 320
                                    shortcut: modelData.shortcut
                                    actionName: modelData.key
                                    onShortcutRecorded: function(newShortcut) { AppController.saveShortcut(modelData.key, newShortcut) }
                                }

                                FlowButton {
                                    label: "Clear"
                                    variant: "secondary"
                                    buttonEnabled: modelData.shortcut.length > 0
                                    onClicked: AppController.saveShortcut(modelData.key, "")
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space12

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Transcription language"
                        subtitle: "Lock Whisper to one language for more speed. Use auto only if you genuinely switch often."
                    }

                    GridLayout {
                        width: parent.width
                        columns: width > 680 ? 3 : 2
                        columnSpacing: theme.space12
                        rowSpacing: theme.space12

                        Repeater {
                            model: AppController.transcriptionLanguageCards

                            delegate: ChoiceCard {
                                Layout.fillWidth: true
                                compact: true
                                hideChevron: true
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

            SectionCard {
                Layout.preferredWidth: 360
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Background behavior"
                        subtitle: "Keep FlowType available like a normal desktop utility."

                        trailing: FlowButton {
                            label: "Apply"
                            variant: "primary"
                            onClicked: AppController.saveStartupSettings(root.launchAtLoginDraft, root.startMinimizedDraft, root.closeToTrayDraft)
                        }
                    }

                    FormRow {
                        width: parent.width
                        title: "Launch at login"
                        subtitle: "Start FlowType when Windows signs in."

                        FlowSwitch {
                            checked: root.launchAtLoginDraft
                            onClicked: root.launchAtLoginDraft = checked
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.divider }

                    FormRow {
                        width: parent.width
                        title: "Start minimized"
                        subtitle: "Open in the tray instead of showing the full window."

                        FlowSwitch {
                            checked: root.startMinimizedDraft
                            onClicked: root.startMinimizedDraft = checked
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.divider }

                    FormRow {
                        width: parent.width
                        title: "Close to tray"
                        subtitle: "Closing the window keeps the app running until you quit from the tray."

                        FlowSwitch {
                            checked: root.closeToTrayDraft
                            onClicked: root.closeToTrayDraft = checked
                        }
                    }
                }
            }
        }

        SectionCard {
            width: parent.width

            ColumnLayout {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Support and app data"
                    subtitle: "Open the underlying folders quickly when you need logs or want to inspect the config."
                }

                RowLayout {
                    Layout.fillWidth: true
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
                        label: "Config File"
                        variant: "secondary"
                        onClicked: AppController.openConfigFile()
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "FlowType v" + AppController.appVersion
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.sizeHelper
                    }
                }
            }
        }
    }
}
