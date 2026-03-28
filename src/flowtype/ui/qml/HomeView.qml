import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    signal navigateRequested(int index)

    function statusTone(value) {
        if (value === "recording")
            return theme.warm
        if (value === "transcribing" || value === "cleaning" || value === "pasting")
            return theme.primary
        if (value === "error")
            return theme.error
        if (value === "ready")
            return theme.success
        return theme.textTertiary
    }

    function currentWaveMode() {
        if (AppController.status === "recording")
            return "recording"
        if (AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting")
            return "busy"
        if (AppController.status === "error")
            return "error"
        return "idle"
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1240
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width
            padding: theme.cardPaddingLarge
            cornerRadius: theme.radiusShell

            RowLayout {
                width: parent.width
                spacing: theme.space24

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.space16

                    Flow {
                        width: parent.width
                        spacing: theme.space8

                        Repeater {
                            model: [
                                "Local Whisper first",
                                AppController.cleanupEnabled ? "Cleanup active" : "Cleanup optional",
                                "Auto paste when ready"
                            ]

                            delegate: TokenChip {
                                label: modelData
                            }
                        }
                    }

                    Label {
                        text: "Dictate, clean, and paste without babysitting the app"
                        color: theme.textPrimary
                        font.family: theme.fontDisplay
                        font.pixelSize: 46
                        font.weight: Font.Black
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "FlowType keeps transcription local, then uses your selected cleanup provider only when you want punctuation polish, filler removal, and smarter sentence shaping."
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textBody
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: theme.space8

                        FlowButton {
                            label: AppController.status === "recording" ? "Finish Dictation" : "Start Dictation"
                            variant: AppController.status === "recording" ? "danger" : "primary"
                            accent: theme.primary
                            onClicked: AppController.toggleRecording()
                        }

                        FlowButton {
                            label: "Open Settings"
                            variant: "secondary"
                            onClicked: root.navigateRequested(4)
                        }

                        FlowButton {
                            label: "Re-paste Last"
                            variant: "secondary"
                            onClicked: AppController.repasteLastText()
                        }
                    }
                }

                SectionCard {
                    Layout.preferredWidth: 330
                    Layout.alignment: Qt.AlignTop
                    baseColor: theme.surfaceSubtle
                    padding: theme.cardPadding

                    Column {
                        width: parent.width
                        spacing: theme.space12

                        Label {
                            text: "Current loop"
                            color: theme.textPrimary
                            font.family: theme.fontDisplay
                            font.pixelSize: theme.sizeSectionTitle
                            font.weight: Font.Bold
                        }

                        InfoRow {
                            width: parent.width
                            label: "Cleanup"
                            value: AppController.cleanupEnabled ? AppController.providerLabel : "Local only"
                        }

                        InfoRow {
                            width: parent.width
                            label: "Model"
                            value: AppController.cleanupEnabled ? AppController.model : "Not active"
                        }

                        InfoRow {
                            width: parent.width
                            label: "Language"
                            value: AppController.transcriptionLanguageLabel
                        }

                        InfoRow {
                            width: parent.width
                            label: "Shortcut"
                            value: AppController.holdToTalk.toUpperCase().split("+").join(" + ")
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: theme.divider
                        }

                        RowLayout {
                            width: parent.width
                            spacing: theme.space8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: root.statusTone(AppController.status)
                            }

                            Label {
                                Layout.fillWidth: true
                                text: AppController.status === "ready" ? "Standing by for your next take" : AppController.detail
                                color: theme.textPrimary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textBody
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space16

            Repeater {
                model: AppController.homeStats

                delegate: MetricTile {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    value: modelData.value
                    label: modelData.label
                    tone: modelData.tone
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 220

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Use it daily without hunting through menus"
                    subtitle: "The product loop stays simple: dictate, let FlowType clean it if you want, and paste it back exactly where you were working."
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 76
                    spacing: theme.space12

                    Repeater {
                        model: [
                            { "tone": theme.primary, "text": "Hold your shortcut for quick dictation, or use a toggle shortcut for longer takes." },
                            { "tone": theme.teal, "text": "If cleanup is off or fails, FlowType still pastes the raw local transcript immediately." },
                            { "tone": theme.warm, "text": "Vocabulary and mode rules feed directly into the cleanup prompt when a provider is active." }
                        ]

                        delegate: RowLayout {
                            width: parent.width
                            spacing: theme.space8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: modelData.tone
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 5
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.text
                                color: theme.textSecondary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textBody
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 328
                Layout.preferredHeight: 220

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Live audio preview"
                    subtitle: "The floating HUD reacts to your microphone while dictation is active."
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 88
                    radius: 24
                    color: theme.inkDark
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    WaveStrip {
                        anchors.centerIn: parent
                        bars: 14
                        barWidth: 4
                        gap: 4
                        minimumBarHeight: 4
                        maximumBarHeight: 26
                        mode: root.currentWaveMode()
                        level: AppController.audioLevel
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
                title: "Recent output"
                subtitle: "The most recent cleaned or raw dictations appear here so you can sanity-check the output quickly."

                trailing: FlowButton {
                    label: "Open Full History"
                    variant: "secondary"
                    onClicked: root.navigateRequested(3)
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 78
                spacing: theme.space12

                EmptyState {
                    visible: AppController.historyItems.length === 0
                    width: parent.width
                    title: "No dictations stored yet"
                    message: "Start one take and the most recent result will appear here."
                }

                Repeater {
                    model: AppController.historyItems

                    delegate: SectionCard {
                        visible: index < 3
                        width: parent.width
                        baseColor: theme.surfaceSubtle
                        padding: theme.cardPadding

                        Column {
                            width: parent.width
                            spacing: theme.space8

                            RowLayout {
                                width: parent.width
                                spacing: theme.space8

                                Label {
                                    text: modelData.createdAt
                                    color: theme.textTertiary
                                    font.family: theme.fontUi
                                    font.pixelSize: theme.textLabel
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: modelData.wordCount + " words"
                                    color: theme.textTertiary
                                    font.family: theme.fontUi
                                    font.pixelSize: theme.textLabel
                                }
                            }

                            Label {
                                width: parent.width
                                text: modelData.finalText
                                color: theme.textPrimary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textBody
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
