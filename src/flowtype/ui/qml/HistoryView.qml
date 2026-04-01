import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 900
        contentSpacing: theme.space24

        // ── Header Actions ───────────────────────────────
        Item {
            width: parent.width
            height: headLabel.implicitHeight

            Label {
                id: headLabel
                text: "Session History"
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizePageTitle
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            FlowButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                label: "Clear History"
                variant: "danger"
                compact: true
                visible: AppController.historyItems.length > 0
                onClicked: AppController.clearHistory()
            }
        }

        // ── Settings ─────────────────────────────────────
        SectionCard {
            width: parent.width

            FormRow {
                width: parent.width
                title: "Keep history between restarts"
                subtitle: "Locally save your dictations to disk so they persist when FlowType closes."

                FlowSwitch {
                    checked: AppController.historyPersist
                    onToggled: (checked) => AppController.saveHistorySettings(AppController.historyMaxItems, checked)
                }
            }
        }

        // ── History List ─────────────────────────────────
        Item {
            width: parent.width
            height: Math.max(200, historyCol.implicitHeight)

            EmptyState {
                visible: AppController.historyItems.length === 0
                title: "No history yet"
                message: "Your transcribed texts will appear here. Dictate something to get started."
            }

            Column {
                id: historyCol
                width: parent.width
                spacing: theme.space12
                visible: AppController.historyItems.length > 0

                Repeater {
                    model: AppController.historyItems

                    delegate: SurfacePanel {
                        width: parent.width
                        baseColor: theme.surface

                        Column {
                            width: parent.width
                            spacing: theme.space12

                            RowLayout {
                                width: parent.width

                                Label {
                                    text: modelData.createdAt
                                    color: theme.textTertiary
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.sizeHelper
                                    Layout.fillWidth: true
                                }
                                
                                Label {
                                    text: modelData.wordCount + " words"
                                    color: theme.textSecondary
                                    font.family: theme.fontUi
                                    font.pixelSize: theme.sizeHelper
                                }
                            }

                            Label {
                                width: parent.width
                                text: modelData.finalText
                                color: theme.textPrimary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeBody
                                wrapMode: Text.WordWrap
                                textFormat: Text.PlainText
                                lineHeight: 1.4
                            }
                            
                            Rectangle { width: parent.width; height: 1; color: theme.divider; visible: modelData.originalText.length > 0 && modelData.originalText !== modelData.finalText }
                            
                            Label {
                                visible: modelData.originalText.length > 0 && modelData.originalText !== modelData.finalText
                                width: parent.width
                                text: "Raw: " + modelData.originalText
                                color: theme.textTertiary
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
}
