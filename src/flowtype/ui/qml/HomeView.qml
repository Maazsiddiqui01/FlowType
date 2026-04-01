import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }
    readonly property var homeStatsData: AppController.homeStats
    readonly property var latestHistoryItem: AppController.historyItems.length > 0 ? AppController.historyItems[0] : null

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1060
        contentSpacing: theme.sectionGap

        // ── Hero section ─────────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space20

                Item { width: 1; height: theme.space8 }

                // Status + greeting
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: theme.space12

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            var s = AppController.status
                            if (s === "recording") return "Listening..."
                            if (s === "transcribing") return "Transcribing your voice..."
                            if (s === "cleaning") return "Polishing your text..."
                            if (s === "pasting") return "Delivering..."
                            if (s === "error") return "Something went wrong"
                            return "Ready to dictate"
                        }
                        color: theme.textPrimary
                        font.family: theme.fontDisplay
                        font.pixelSize: theme.sizePageTitle
                        font.weight: Font.Bold
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (AppController.status === "error") return AppController.detail
                            if (!AppController.cleanupEnabled) return "Local transcription only — no cleanup provider configured"
                            return "Hold " + (AppController.holdToTalk.length > 0 ? AppController.holdToTalk : "your shortcut") + " to start recording"
                        }
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeBody
                    }
                }

                // Waveform preview
                Item {
                    width: parent.width
                    height: 44
                    anchors.horizontalCenter: parent.horizontalCenter

                    WaveStrip {
                        anchors.centerIn: parent
                        bars: 16
                        barWidth: 4
                        gap: 4
                        minimumBarHeight: 4
                        maximumBarHeight: 28
                        level: AppController.audioLevel
                        mode: {
                            var s = AppController.status
                            if (s === "recording") return "recording"
                            if (s === "error") return "error"
                            if (s === "transcribing" || s === "cleaning" || s === "pasting") return "busy"
                            return "idle"
                        }
                    }
                }

                // Quick info chips
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: theme.space8

                    TokenChip {
                        label: AppController.cleanupEnabled
                            ? (AppController.providerLabel + " · " + AppController.model)
                            : "Local only"
                        tone: AppController.cleanupEnabled ? theme.primary : theme.textTertiary
                    }

                    TokenChip {
                        label: AppController.transcriptionLanguageLabel
                        tone: theme.teal
                    }

                    TokenChip {
                        label: AppController.whisperModel
                        tone: theme.warm
                    }
                }

                Item { width: 1; height: theme.space4 }
            }
        }

        // ── Metric tiles ─────────────────────────────────
        RowLayout {
            width: parent.width
            spacing: theme.space12

            MetricTile {
                Layout.fillWidth: true
                value: root.homeStatsData.length > 0 ? root.homeStatsData[0].value : "0"
                label: "Total dictations"
                tone: theme.primary
            }

            MetricTile {
                Layout.fillWidth: true
                value: root.homeStatsData.length > 1 ? root.homeStatsData[1].value : "0"
                label: "Words generated"
                tone: theme.teal
            }

            MetricTile {
                Layout.fillWidth: true
                value: root.homeStatsData.length > 2 ? root.homeStatsData[2].value : "0"
                label: "Auto-pasted"
                tone: theme.warm
            }

            MetricTile {
                Layout.fillWidth: true
                value: AppController.cleanupEnabled ? "On" : "Off"
                label: "Cleanup status"
                tone: AppController.cleanupEnabled ? theme.success : theme.textTertiary
            }
        }

        // ── Recent output ────────────────────────────────
        SectionCard {
            width: parent.width
            visible: root.latestHistoryItem !== null

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Latest output"
                subtitle: "Your most recent dictation result."
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 72
                spacing: theme.space12

                Label {
                    width: parent.width
                    text: AppController.historyItems.length > 0
                        ? root.latestHistoryItem.finalText
                        : ""
                    color: theme.textPrimary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeBody
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                }

                Row {
                    spacing: theme.space8
                    visible: root.latestHistoryItem !== null

                    TokenChip {
                        label: root.latestHistoryItem !== null ? root.latestHistoryItem.createdAt : ""
                        tone: theme.textTertiary
                    }

                    TokenChip {
                        label: root.latestHistoryItem !== null ? (root.latestHistoryItem.wordCount + " words") : ""
                        tone: theme.textTertiary
                    }
                }
            }
        }

        // ── Alert cards ──────────────────────────────────
        SectionCard {
            width: parent.width
            visible: AppController.needsApiKey
            baseColor: theme.darkMode ? "#1A1520" : "#FFF8F0"

            RowLayout {
                width: parent.width
                spacing: theme.space12

                Rectangle {
                    width: 6
                    Layout.fillHeight: true
                    radius: 3
                    color: theme.warm
                }

                Column {
                    Layout.fillWidth: true
                    spacing: theme.space4

                    Label {
                        text: "No API key configured"
                        color: theme.textPrimary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeCardTitle
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "Add your " + AppController.providerLabel + " API key in Cleanup settings to enable text cleanup."
                        width: parent.width
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeHelper
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
