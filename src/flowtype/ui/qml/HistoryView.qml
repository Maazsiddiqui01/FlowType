import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1180
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            RowLayout {
                width: parent.width
                spacing: theme.space16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: "Session history"
                        color: theme.textPrimary
                        font.family: theme.fontDisplay
                        font.pixelSize: theme.sizeSectionTitle
                        font.weight: 700
                    }

                    Label {
                        text: "Recent dictations stay on this device. Keep history on if you want them across restarts."
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeHelper
                    }
                }

                FlowSwitch {
                    checked: AppController.historyPersist
                    onToggled: function(checked) { AppController.saveHistorySettings(AppController.historyMaxItems, checked) }
                }

                FlowButton {
                    label: "Clear History"
                    variant: "danger"
                    buttonEnabled: AppController.historyItems.length > 0
                    onClicked: AppController.clearHistory()
                }
            }
        }

        EmptyState {
            visible: AppController.historyItems.length === 0
            width: parent.width
            title: "No history yet"
            message: "Once you dictate something, FlowType will show the cleaned result and the raw fallback text here."
        }

        Column {
            width: parent.width
            spacing: theme.space12
            visible: AppController.historyItems.length > 0

            Repeater {
                model: AppController.historyItems

                delegate: SectionCard {
                    width: parent.width

                    ColumnLayout {
                        width: parent.width
                        spacing: theme.space12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: theme.space12

                            Label {
                                text: modelData.createdAt
                                color: theme.textTertiary
                                font.family: theme.fontMono
                                font.pixelSize: theme.sizeHelper
                            }

                            TokenChip {
                                label: modelData.provider
                                tone: theme.primary
                            }

                            TokenChip {
                                label: modelData.mode
                                tone: theme.teal
                            }

                            TokenChip {
                                visible: modelData.usedFallback
                                label: "Fallback"
                                tone: theme.warm
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: modelData.wordCount + " words"
                                color: theme.textSecondary
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeHelper
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.finalText
                            color: theme.textPrimary
                            font.family: theme.fontText
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: theme.divider
                            visible: modelData.rawText.length > 0 && modelData.rawText !== modelData.finalText
                        }

                        Label {
                            visible: modelData.rawText.length > 0 && modelData.rawText !== modelData.finalText
                            Layout.fillWidth: true
                            text: modelData.rawText
                            color: theme.textSecondary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeHelper
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }
                    }
                }
            }
        }
    }
}
