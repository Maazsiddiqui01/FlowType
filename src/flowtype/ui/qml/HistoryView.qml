import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1160
        contentSpacing: 20

        SurfacePanel {
            width: parent.width
            prominent: true
            accent: "#ec4899"
            cornerRadius: 28
            padding: 24

            Column {
                width: parent.width
                spacing: 14

                RowLayout {
                    width: parent.width

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Recent dictation history"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 31
                            font.weight: Font.Black
                        }

                        Label {
                            text: "History stays local to this device so you can compare the cleaned output with the raw transcript and sanity-check provider behavior."
                            color: "#627b8e"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

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

                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: AppController.homeStats

                        delegate: MetricTile {
                            width: (parent.width - 36) / 4
                            value: modelData.value
                            label: modelData.label
                            tone: modelData.tone
                        }
                    }
                }
            }
        }

        Label {
            visible: AppController.historyItems.length === 0
            width: parent.width
            text: "Nothing stored yet. Run one full dictation and the result will appear here."
            color: "#72879a"
            font.family: "Segoe UI Variable Text"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: AppController.historyItems

            delegate: SurfacePanel {
                width: parent.width
                cornerRadius: 22
                accent: modelData.usedFallback ? "#f97316" : "#0d9488"
                padding: 18

                Column {
                    width: parent.width
                    spacing: 10

                    RowLayout {
                        width: parent.width

                        Label {
                            text: modelData.createdAt
                            color: "#72879a"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 11
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: modelData.wordCount + " words"
                            color: "#72879a"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 11
                        }

                        Label {
                            text: modelData.provider + " | " + modelData.model
                            color: "#72879a"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        spacing: 8

                        Repeater {
                            model: [
                                modelData.pasted ? "Pasted" : "Clipboard only",
                                modelData.usedFallback ? "Raw fallback" : "Cleanup applied"
                            ]

                            delegate: Rectangle {
                                radius: 13
                                color: "#f4f8fb"
                                border.width: 1
                                border.color: "#dce7ed"
                                implicitWidth: stateText.implicitWidth + 16
                                implicitHeight: 28

                                Label {
                                    id: stateText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "#36566c"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Label {
                        width: parent.width
                        text: modelData.finalText
                        color: "#173042"
                        wrapMode: Text.WordWrap
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                    }

                    Label {
                        visible: modelData.rawText.length > 0 && modelData.rawText !== modelData.finalText
                        width: parent.width
                        text: "Raw: " + modelData.rawText
                        color: "#708698"
                        wrapMode: Text.WordWrap
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
