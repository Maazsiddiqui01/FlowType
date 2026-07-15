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

    // Transient "Copied" hint shown after tapping a recent result.
    property int copiedIndex: -1
    Timer {
        id: copiedTimer
        interval: 1200
        onTriggered: resultWindow.copiedIndex = -1
    }
    function copyRecent(index) {
        AppController.copyRecentResult(index)
        resultWindow.copiedIndex = index
        copiedTimer.restart()
    }

    width: 460
    height: card.implicitHeight + 16

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: resultWindow.width
        implicitHeight: contentColumn.implicitHeight + theme.space20 * 2
        radius: theme.radiusCard
        color: theme.darkMode ? "#0D131D" : theme.surface
        border.width: 1
        border.color: theme.tint(resultWindow.toneColor, theme.darkMode ? 0.42 : 0.24)

        // Soft top sheen for depth
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 64
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, theme.darkMode ? 0.04 : 0.30) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: theme.space20
            spacing: theme.space12

            // ── Header ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: theme.space12

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 9
                    height: 9
                    radius: 4.5
                    color: resultWindow.toneColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Label {
                        Layout.fillWidth: true
                        text: AppController.resultCardTitle
                        color: theme.textPrimary
                        font.family: theme.fontDisplay
                        font.pixelSize: 15
                        font.weight: 700
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: AppController.resultCardMessage
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeHelper
                        elide: Text.ElideRight
                    }
                }

                ToolButton {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 26
                    implicitHeight: 26
                    background: Rectangle {
                        radius: 13
                        color: parent.hovered ? theme.surfaceHover : "transparent"
                    }
                    contentItem: Label {
                        text: "✕"
                        color: theme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: AppController.dismissResultCard()
                }
            }

            // ── Primary result (scrolls when long) ───────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: AppController.resultCardPreview.length > 0
                radius: theme.radiusControl
                color: theme.surfaceSubtle
                border.width: 1
                border.color: theme.border
                implicitHeight: Math.min(previewText.implicitHeight + theme.space12 * 2, 148)

                Flickable {
                    id: previewFlick
                    anchors.fill: parent
                    anchors.margins: theme.space12
                    clip: true
                    contentHeight: previewText.implicitHeight
                    contentWidth: width
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height
                    ScrollBar.vertical: ScrollBar {
                        policy: previewFlick.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        width: 4
                    }

                    Label {
                        id: previewText
                        width: previewFlick.width
                        text: AppController.resultCardPreview
                        color: theme.textPrimary
                        font.family: theme.fontText
                        font.pixelSize: 14
                        lineHeight: 1.25
                        wrapMode: Text.WordWrap
                    }
                }

                // Fade hint at the bottom when there's more to scroll
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    height: 24
                    radius: parent.radius - 1
                    visible: previewFlick.interactive
                        && previewFlick.contentY < previewFlick.contentHeight - previewFlick.height - 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: theme.surfaceSubtle }
                    }
                }
            }

            // ── Recent results (clean vertical list) ─────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                visible: AppController.recentResultItems.length > 0
                spacing: theme.space8

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Recent"
                        color: theme.textTertiary
                        font.family: theme.fontUi
                        font.pixelSize: theme.sizeLabel
                        font.weight: 700
                        font.capitalization: Font.AllUppercase
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "Tap to copy"
                        color: theme.textTertiary
                        font.family: theme.fontUi
                        font.pixelSize: theme.sizeLabel
                    }
                }

                Repeater {
                    model: AppController.recentResultItems

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: theme.controlHeightCompact
                        radius: theme.radiusControl
                        color: rowArea.containsMouse ? theme.surfaceHover : theme.surfaceSubtle
                        border.width: 1
                        border.color: rowArea.containsMouse ? theme.borderSelected : theme.border

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: theme.space12
                            anchors.rightMargin: theme.space12
                            spacing: theme.space8

                            Label {
                                Layout.fillWidth: true
                                text: modelData.finalText
                                color: theme.textPrimary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeHelper
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            // "Copied" confirmation, else word count on hover
                            Label {
                                visible: resultWindow.copiedIndex === index || (rowArea.containsMouse && modelData.wordCount > 0)
                                text: resultWindow.copiedIndex === index
                                    ? "Copied"
                                    : modelData.wordCount + "w"
                                color: resultWindow.copiedIndex === index ? theme.success : theme.textTertiary
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeLabel
                                font.weight: 650
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: resultWindow.copyRecent(index)
                        }
                    }
                }
            }

            // ── Actions ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: theme.space4
                spacing: theme.space8

                readonly property bool isError: AppController.resultCardTone === "error"

                FlowButton {
                    visible: parent.isError
                    label: "Open Settings"
                    variant: "primary"
                    onClicked: AppController.requestOpenSettings()
                }

                FlowButton {
                    visible: !parent.isError
                    label: "Copy"
                    variant: "secondary"
                    onClicked: AppController.copyLatestResult()
                }

                FlowButton {
                    visible: !parent.isError
                    label: "Re-paste"
                    variant: "secondary"
                    buttonEnabled: AppController.resultCardCanRepaste
                    onClicked: AppController.repasteLastText()
                }

                FlowButton {
                    visible: !parent.isError
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
