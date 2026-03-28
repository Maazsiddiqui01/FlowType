import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1160
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Recent dictation history"
                subtitle: "History stays local to this device so you can compare the cleaned output with the raw transcript."

                trailing: Row {
                    spacing: theme.space8

                    FlowButton {
                        label: "Open Config"
                        variant: "secondary"
                        onClicked: AppController.openConfigFile()
                    }

                    FlowButton {
                        label: "Clear History"
                        variant: "danger"
                        onClicked: AppController.clearHistory()
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 74
                spacing: theme.space8

                Repeater {
                    model: [
                        { "label": "Stored locally", "value": "Yes" },
                        { "label": "Cleanup provider", "value": AppController.cleanupEnabled ? AppController.providerLabel : "Local only" },
                        { "label": "Fallback safe", "value": "Enabled" }
                    ]

                    delegate: TokenChip {
                        label: modelData.label + ": " + modelData.value
                    }
                }
            }
        }

        EmptyState {
            visible: AppController.historyItems.length === 0
            width: parent.width
            title: "Nothing stored yet"
            message: "Run one full dictation and the result will appear here."
        }

        Repeater {
            model: AppController.historyItems

            delegate: SectionCard {
                width: parent.width
                baseColor: theme.surface

                Column {
                    width: parent.width
                    spacing: theme.space12

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

                        ProviderBadge {
                            compact: true
                            providerId: modelData.providerId
                            badgeBackground: theme.surfaceSubtle
                        }

                        Label {
                            text: modelData.provider + " • " + modelData.model
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textLabel
                        }

                        Label {
                            text: modelData.wordCount + " words"
                            color: theme.textTertiary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textLabel
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: theme.space8

                        TokenChip {
                            label: modelData.pasted ? "Pasted" : "Clipboard only"
                        }

                        TokenChip {
                            label: modelData.usedFallback ? "Raw fallback" : "Cleanup applied"
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

                    Rectangle {
                        visible: modelData.rawText.length > 0 && modelData.rawText !== modelData.finalText
                        width: parent.width
                        radius: theme.radiusControl
                        color: theme.surfaceSubtle
                        border.width: 1
                        border.color: theme.divider
                        implicitHeight: rawLabel.implicitHeight + 24

                        Label {
                            id: rawLabel
                            anchors.fill: parent
                            anchors.margins: 12
                            text: "Raw transcript: " + modelData.rawText
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textHelper
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
