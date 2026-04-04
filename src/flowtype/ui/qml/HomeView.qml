import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    readonly property var homeStatsData: AppController.homeStats
    readonly property var recentItems: AppController.recentResultItems

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1220
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            RowLayout {
                width: parent.width
                spacing: theme.space24

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.space16

                    Flow {
                        Layout.fillWidth: true
                        spacing: theme.space8

                        TokenChip {
                            label: "Local Whisper first"
                            tone: theme.primary
                        }

                        TokenChip {
                            label: AppController.cleanupEnabled ? "Cleanup active" : "Local only"
                            tone: AppController.cleanupEnabled ? theme.success : theme.textTertiary
                        }

                        TokenChip {
                            label: AppController.transcriptionLanguageLabel
                            tone: theme.teal
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Dictate, clean, and paste without babysitting the app"
                        color: theme.textPrimary
                        font.family: theme.fontDisplay
                        font.pixelSize: 34
                        font.weight: 780
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        Layout.fillWidth: true
                        text: AppController.cleanupEnabled
                            ? "FlowType transcribes locally, then uses your selected provider for cleanup only when you want smarter punctuation and filler removal."
                            : "FlowType is ready for fast local dictation. Add a cleanup provider anytime if you want extra punctuation and grammar polish."
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeBody
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        spacing: theme.space12

                        FlowButton {
                            label: "Start Dictation"
                            variant: "primary"
                            onClicked: AppController.toggleRecording()
                        }

                        FlowButton {
                            label: "Re-paste Last"
                            variant: "secondary"
                            buttonEnabled: AppController.historyItems.length > 0
                            onClicked: AppController.repasteLastText()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: summaryColumn.implicitHeight + theme.space16 * 2
                    radius: theme.radiusCard
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: summaryColumn
                        anchors.fill: parent
                        anchors.margins: theme.space16
                        spacing: theme.space12

                        Label {
                            text: "Current loop"
                            color: theme.textPrimary
                            font.family: theme.fontDisplay
                            font.pixelSize: theme.sizeSectionTitle
                            font.weight: 700
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: theme.space12
                            rowSpacing: theme.space8

                            Repeater {
                                model: [
                                    { "label": "Cleanup", "value": AppController.cleanupEnabled ? AppController.providerLabel : "Local only" },
                                    { "label": "Model", "value": AppController.cleanupEnabled ? AppController.model : "Raw transcript" },
                                    { "label": "Language", "value": AppController.transcriptionLanguageLabel },
                                    { "label": "Shortcut", "value": AppController.holdToTalk.toUpperCase() }
                                ]

                                delegate: Item {
                                    Layout.fillWidth: true
                                    implicitHeight: 40

                                    Column {
                                        anchors.fill: parent
                                        spacing: 2

                                        Label {
                                            text: modelData.label
                                            color: theme.textTertiary
                                            font.family: theme.fontUi
                                            font.pixelSize: theme.sizeLabel
                                        }

                                        Label {
                                            text: modelData.value
                                            color: theme.textPrimary
                                            font.family: theme.fontUi
                                            font.pixelSize: theme.sizeBody
                                            font.weight: 650
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: theme.divider
                        }

                        Label {
                            Layout.fillWidth: true
                            text: AppController.detail
                            color: theme.textSecondary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeHelper
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space12

            Repeater {
                model: root.homeStatsData

                delegate: MetricTile {
                    Layout.fillWidth: true
                    value: modelData.value
                    label: modelData.label
                    tone: modelData.tone
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space12

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 2

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "How it works day to day"
                        subtitle: "A few quiet defaults that keep daily dictation predictable."
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.space12

                        Repeater {
                            model: [
                                "Hold your push-to-talk shortcut for quick dictation, or use toggle recording for longer takes.",
                                "If cleanup is disabled or slow, FlowType still falls back to the local transcript instead of blocking you.",
                                "Vocabulary entries and the active mode are added to the cleanup prompt when a provider is enabled."
                            ]

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: theme.space12

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 4
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: index === 0 ? theme.primary : (index === 1 ? theme.teal : theme.warm)
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData
                                    color: theme.textSecondary
                                    font.family: theme.fontText
                                    font.pixelSize: theme.sizeBody
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Live audio preview"
                        subtitle: "The floating HUD mirrors this visual language while you speak."
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96
                        radius: theme.radiusCard
                        color: theme.darkMode ? "#0C1220" : "#0C1622"

                        WaveStrip {
                            anchors.centerIn: parent
                            bars: 9
                            barWidth: 5
                            gap: 5
                            minimumBarHeight: 4
                            maximumBarHeight: 24
                            level: Math.max(AppController.audioLevel, 0.18)
                            mode: AppController.status === "recording"
                                ? "recording"
                                : (AppController.status === "error"
                                    ? "error"
                                    : ((AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting")
                                        ? "busy" : "idle"))
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
                    title: "Recent output"
                    subtitle: root.recentItems.length > 0
                        ? "The latest results stay easy to recover if you want to sanity-check or copy again."
                        : "Your latest dictation will appear here once you start using the app."
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: theme.space12
                    visible: root.recentItems.length > 0

                    Repeater {
                        model: root.recentItems.slice(0, 3)

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: previewColumn.implicitHeight + theme.space12 * 2
                            radius: theme.radiusCard
                            color: theme.surfaceSubtle
                            border.width: 1
                            border.color: theme.border

                            ColumnLayout {
                                id: previewColumn
                                anchors.fill: parent
                                anchors.margins: theme.space12
                                spacing: theme.space8

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.finalText
                                    color: theme.textPrimary
                                    font.family: theme.fontText
                                    font.pixelSize: 14
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }

                                Row {
                                    spacing: theme.space8

                                    TokenChip { label: modelData.createdAt; tone: theme.textTertiary }
                                    TokenChip { label: modelData.wordCount + " words"; tone: theme.textTertiary }
                                    TokenChip { label: modelData.pasted ? "Pasted" : "Copied"; tone: modelData.pasted ? theme.success : theme.primary }
                                }
                            }
                        }
                    }
                }

                EmptyState {
                    visible: root.recentItems.length === 0
                    title: "No output yet"
                    message: "Dictate a short phrase and FlowType will show the latest result here."
                }
            }
        }
    }
}
