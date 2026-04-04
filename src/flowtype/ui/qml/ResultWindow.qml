import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: resultWindow

    Theme { id: theme }

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: AppController.resultCardVisible

    property color toneColor: {
        if (AppController.resultCardTone === "success") return theme.success
        if (AppController.resultCardTone === "error") return theme.error
        return theme.primary
    }

    width: 428
    height: card.implicitHeight + 16

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: resultWindow.width
        implicitHeight: contentColumn.implicitHeight + theme.space16 * 2
        radius: 18
        color: theme.darkMode ? "#0D131D" : theme.surface
        border.width: 1
        border.color: theme.tint(resultWindow.toneColor, theme.darkMode ? 0.42 : 0.24)

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: theme.space16
            spacing: theme.space12

            RowLayout {
                Layout.fillWidth: true
                spacing: theme.space12

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: resultWindow.toneColor
                }

                Label {
                    Layout.fillWidth: true
                    text: AppController.resultCardTitle
                    color: theme.textPrimary
                    font.family: theme.fontDisplay
                    font.pixelSize: 16
                    font.weight: 700
                    elide: Text.ElideRight
                }

                ToolButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    background: Rectangle {
                        radius: 14
                        color: parent.hovered ? theme.surfaceHover : "transparent"
                    }
                    contentItem: Label {
                        text: "\u2715"
                        color: theme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: AppController.dismissResultCard()
                }
            }

            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: AppController.resultCardMessage
                color: theme.textSecondary
                font.family: theme.fontText
                font.pixelSize: theme.sizeBody
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                visible: AppController.resultCardPreview.length > 0
                radius: theme.radiusCard
                color: theme.surfaceSubtle
                border.width: 1
                border.color: theme.border
                implicitHeight: previewText.implicitHeight + theme.space12 * 2

                Label {
                    id: previewText
                    anchors.fill: parent
                    anchors.margins: theme.space12
                    text: AppController.resultCardPreview
                    color: theme.textPrimary
                    font.family: theme.fontText
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: AppController.recentResultItems.length > 0
                spacing: theme.space8

                Label {
                    text: "Recent results"
                    color: theme.textTertiary
                    font.family: theme.fontUi
                    font.pixelSize: theme.sizeLabel
                    font.weight: 650
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: theme.space8

                    Repeater {
                        model: AppController.recentResultItems

                        delegate: Rectangle {
                            width: Math.min(182, label.implicitWidth + theme.space16)
                            height: theme.controlHeightCompact
                            radius: theme.radiusControl
                            color: copyArea.containsMouse ? theme.surfaceHover : theme.surfaceSubtle
                            border.width: 1
                            border.color: theme.border

                            Label {
                                id: label
                                anchors.fill: parent
                                anchors.leftMargin: theme.space12
                                anchors.rightMargin: theme.space12
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.finalText
                                color: theme.textPrimary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeHelper
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: copyArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AppController.copyRecentResult(index)
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: theme.space8

                FlowButton {
                    label: "Copy"
                    variant: "secondary"
                    onClicked: AppController.copyLatestResult()
                }

                FlowButton {
                    label: "Re-paste"
                    variant: "secondary"
                    buttonEnabled: AppController.resultCardCanRepaste
                    onClicked: AppController.repasteLastText()
                }

                FlowButton {
                    label: AppController.resultCardEnhancing ? "Enhancing..." : "Enhance for AI"
                    variant: "secondary"
                    buttonEnabled: AppController.resultCardCanEnhance
                    onClicked: AppController.enhanceLatestResultForAi()
                }

                Item { Layout.fillWidth: true }

                FlowButton {
                    label: AppController.resultCardPersistent ? "Close" : "Dismiss"
                    variant: "ghost"
                    onClicked: AppController.dismissResultCard()
                }
            }
        }
    }
}
