import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    readonly property var statsData: AppController.homeStats
    readonly property var recentItems: AppController.recentResultItems

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1080
        contentSpacing: theme.sectionGap

        // ── Greeting + at-a-glance stats ─────────────────────────────────────
        RowLayout {
            width: parent.width
            spacing: theme.space24

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: theme.space8

                Label {
                    text: "Welcome back"
                    color: theme.textPrimary
                    font.family: theme.fontDisplay
                    font.pixelSize: 30
                    font.weight: 780
                }

                Label {
                    Layout.fillWidth: true
                    text: "Hold " + AppController.holdToTalk.toUpperCase() + " and speak — FlowType transcribes locally"
                        + (AppController.cleanupEnabled ? ", cleans it up," : "") + " and pastes it into whatever you're typing."
                    color: theme.textSecondary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeBody
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: theme.space4
                    spacing: theme.space8

                    TokenChip { label: "Local Whisper"; tone: theme.primary }
                    TokenChip {
                        label: AppController.cleanupEnabled ? AppController.providerLabel : "Local only"
                        tone: AppController.cleanupEnabled ? theme.success : theme.textTertiary
                    }
                    TokenChip { label: AppController.transcriptionLanguageLabel; tone: theme.teal }
                }
            }

            Rectangle {
                Layout.preferredWidth: 232
                Layout.alignment: Qt.AlignTop
                implicitHeight: statsColumn.implicitHeight + theme.space20 * 2
                radius: theme.radiusCard
                color: theme.surfaceSubtle
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: statsColumn
                    anchors.fill: parent
                    anchors.margins: theme.space20
                    spacing: theme.space16

                    Repeater {
                        model: root.statsData

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: theme.space12

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 8; height: 8; radius: 4
                                color: modelData.tone
                            }

                            Label {
                                text: modelData.value
                                color: theme.textPrimary
                                font.family: theme.fontDisplay
                                font.pixelSize: 24
                                font.weight: 760
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.label
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

        // ── Recent dictations timeline ───────────────────────────────────────
        SectionCard {
            width: parent.width

            ColumnLayout {
                width: parent.width
                spacing: theme.space8

                SectionHeader {
                    title: "Recent dictations"
                    subtitle: root.recentItems.length > 0
                        ? "Your latest results — copy any of them, or review everything in History."
                        : "Your dictations will appear here."
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: theme.space8
                    spacing: 0
                    visible: root.recentItems.length > 0

                    Repeater {
                        model: root.recentItems

                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: theme.space12
                                Layout.bottomMargin: theme.space12
                                spacing: theme.space16

                                Label {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.preferredWidth: 116
                                    text: modelData.createdAt
                                    color: theme.textTertiary
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.sizeHelper
                                }

                                Label {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    text: modelData.finalText
                                    color: theme.textPrimary
                                    font.family: theme.fontText
                                    font.pixelSize: theme.sizeBody
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }

                                FlowButton {
                                    Layout.alignment: Qt.AlignTop
                                    label: "Copy"
                                    variant: "ghost"
                                    compact: true
                                    onClicked: AppController.copyRecentResult(index)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: theme.divider
                                visible: index < root.recentItems.length - 1
                            }
                        }
                    }
                }

                EmptyState {
                    visible: root.recentItems.length === 0
                    title: "No dictations yet"
                    message: "Hold your shortcut and speak. FlowType transcribes locally, optionally cleans it up, and pastes it into whatever you're typing."
                }
            }
        }
    }
}
