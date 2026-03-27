import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    signal navigateRequested(int index)

    function currentWaveMode() {
        if (AppController.status === "recording")
            return "recording"
        if (AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting")
            return "busy"
        return "idle"
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1180
        contentSpacing: 20

        SurfacePanel {
            width: parent.width
            prominent: true
            accent: "#0d9488"
            cornerRadius: 28
            padding: 26

            RowLayout {
                width: parent.width
                spacing: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: [
                                "Local Whisper first",
                                AppController.cleanupEnabled ? "Cleanup active" : "Cleanup optional",
                                "Auto paste when ready"
                            ]

                            delegate: Rectangle {
                                radius: 14
                                color: "#eef7f6"
                                border.width: 1
                                border.color: "#d0ece7"
                                implicitWidth: chipText.implicitWidth + 20
                                implicitHeight: 32

                                Label {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "#1c4a52"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    Label {
                        text: "Dictate, clean, and paste without babysitting the app"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 34
                        font.weight: Font.Black
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "FlowType keeps transcription local, then uses your selected cleanup provider only when you want grammar polish, filler removal, and smarter sentence shaping."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 10

                        FlowButton {
                            label: AppController.status === "recording" ? "Finish Dictation" : "Start Dictation"
                            variant: AppController.status === "recording" ? "danger" : "primary"
                            accent: "#2563eb"
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

                SurfacePanel {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 214
                    accent: "#2563eb"
                    cornerRadius: 24
                    padding: 18

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        Label {
                            text: "Current loop"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 22
                            font.weight: Font.Black
                        }

                        Repeater {
                            model: [
                                { "label": "Cleanup", "value": AppController.cleanupEnabled ? AppController.providerLabel : "Local only right now" },
                                { "label": "Model", "value": AppController.cleanupEnabled ? AppController.model : "Not active" },
                                { "label": "Language", "value": AppController.transcriptionLanguageLabel },
                                { "label": "Shortcut", "value": AppController.holdToTalk.toUpperCase().split("+").join(" + ") }
                            ]

                            delegate: RowLayout {
                                width: parent.width

                                Label {
                                    text: modelData.label
                                    color: "#708698"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: modelData.value
                                    color: "#173042"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        SurfacePanel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            accent: AppController.status === "ready" ? "#0d9488" : "#2563eb"
                            cornerRadius: 18
                            padding: 12

                            RowLayout {
                                anchors.fill: parent
                                spacing: 12

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: AppController.status === "ready" ? "#0d9488" : "#2563eb"
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: AppController.status === "ready" ? "Standing by for your next take" : AppController.detail
                                    color: "#173042"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
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

        RowLayout {
            width: parent.width
            spacing: 18

            SurfacePanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 218
                accent: "#2563eb"
                cornerRadius: 24
                padding: 22

                Column {
                    width: parent.width
                    spacing: 14

                    Label {
                        text: "Use it daily without hunting through menus"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 24
                        font.weight: Font.Black
                    }

                    Repeater {
                        model: [
                            "Hold your shortcut for quick dictation, or set a toggle shortcut for longer takes.",
                            "If cleanup is disabled, FlowType still pastes the raw local transcript immediately.",
                            "Vocabulary and mode rules feed directly into the cleanup prompt when a provider is active."
                        ]

                        delegate: RowLayout {
                            width: parent.width
                            spacing: 10

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: index === 0 ? "#2563eb" : (index === 1 ? "#0d9488" : "#f97316")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData
                                color: "#627b8e"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            SurfacePanel {
                Layout.preferredWidth: 318
                Layout.preferredHeight: 218
                accent: "#f97316"
                cornerRadius: 24
                padding: 22

                Column {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: "Live audio preview"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 22
                        font.weight: Font.Black
                    }

                    Label {
                        width: parent.width
                        text: "The tiny bottom HUD expands only when active. It stays subtle while idle and mirrors live audio while you speak."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    SurfacePanel {
                        width: parent.width
                        height: 78
                        cornerRadius: 22
                        accent: "#163042"
                        baseColor: "#081018"
                        padding: 16

                        WaveStrip {
                            anchors.centerIn: parent
                            bars: 14
                            barWidth: 4
                            gap: 4
                            minimumBarHeight: 4
                            maximumBarHeight: 24
                            mode: root.currentWaveMode()
                            level: AppController.audioLevel
                        }
                    }
                }
            }
        }

        SurfacePanel {
            width: parent.width
            accent: "#ec4899"
            cornerRadius: 24
            padding: 22

            Column {
                width: parent.width
                spacing: 14

                RowLayout {
                    width: parent.width

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Recent output"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 24
                            font.weight: Font.Black
                        }

                        Label {
                            text: "The most recent cleaned or raw dictations appear here so you can sanity-check the output quickly."
                            color: "#627b8e"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    FlowButton {
                        label: "Open Full History"
                        variant: "secondary"
                        onClicked: root.navigateRequested(3)
                    }
                }

                Label {
                    visible: AppController.historyItems.length === 0
                    width: parent.width
                    text: "No dictations stored yet. Start one take and the most recent result will appear here."
                    color: "#72879a"
                    font.family: "Segoe UI Variable Text"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: AppController.historyItems

                    delegate: SurfacePanel {
                        visible: index < 3
                        width: parent.width
                        cornerRadius: 18
                        accent: modelData.usedFallback ? "#f97316" : "#0d9488"
                        padding: 16

                        Column {
                            width: parent.width
                            spacing: 8

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
                            }

                            Label {
                                width: parent.width
                                text: modelData.finalText
                                color: "#173042"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
