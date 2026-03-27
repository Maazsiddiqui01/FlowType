import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string selectedMode: AppController.activeMode
    property string customPromptDraft: AppController.customModePrompt

    Connections {
        target: AppController

        function onConfigChanged() {
            root.selectedMode = AppController.activeMode
            root.customPromptDraft = AppController.customModePrompt
        }
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1160
        contentSpacing: 20

        SurfacePanel {
            width: parent.width
            prominent: true
            accent: "#3b82f6"
            cornerRadius: 28
            padding: 24
            borderTone: "#dfe8ef"

            RowLayout {
                width: parent.width
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: "Modes shape cleanup without adding more friction"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 29
                        font.weight: Font.Black
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Pick one active preset for the way you usually work. Add only the extra notes that matter, and the cleanup prompt stays consistent."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                FlowButton {
                    label: "Save Mode"
                    variant: "primary"
                    accent: "#2563eb"
                    onClicked: AppController.saveModeSettings(root.selectedMode, root.customPromptDraft)
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: 18

            SurfacePanel {
                Layout.fillWidth: true
                accent: "#3b82f6"
                cornerRadius: 24
                padding: 20
                borderTone: "#dfe8ef"

                Column {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: "Preset cards"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 23
                        font.weight: Font.Black
                    }

                    Flow {
                        width: parent.width
                        spacing: 12

                        Repeater {
                            model: AppController.modeCards

                            delegate: Rectangle {
                                width: (parent.width - 12) / 2
                                height: 122
                                radius: 20
                                color: root.selectedMode === modelData.identifier ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.12) : "#ffffff"
                                border.width: 1
                                border.color: root.selectedMode === modelData.identifier ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.55) : "#dbe7ee"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 10

                                    RowLayout {
                                        width: parent.width

                                        Rectangle {
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: modelData.accent
                                        }

                                        Label {
                                            text: modelData.label
                                            color: "#163042"
                                            font.family: "Segoe UI Variable Text"
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                        }

                                        Item { Layout.fillWidth: true }

                                        Label {
                                            text: root.selectedMode === modelData.identifier ? "ACTIVE" : ""
                                            color: "#50718a"
                                            font.family: "Bahnschrift SemiBold"
                                            font.pixelSize: 11
                                        }
                                    }

                                    Label {
                                        width: parent.width
                                        text: modelData.summary
                                        color: "#627b8e"
                                        font.family: "Segoe UI Variable Text"
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedMode = modelData.identifier
                                }
                            }
                        }
                    }
                }
            }

            SurfacePanel {
                Layout.preferredWidth: 306
                accent: "#0d9488"
                cornerRadius: 24
                padding: 20
                borderTone: "#dfe8ef"

                Column {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: "Prompt stack"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 23
                        font.weight: Font.Black
                    }

                    Repeater {
                        model: [
                            "Base cleanup prompt",
                            "Selected mode preset",
                            "Your custom notes",
                            "Vocabulary entries"
                        ]

                        delegate: Rectangle {
                            width: parent.width
                            height: 54
                            radius: 16
                            color: "#f7fafc"
                            border.width: 1
                            border.color: "#dfe9ef"

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                text: modelData
                                color: "#34566c"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }

        SurfacePanel {
            width: parent.width
            accent: "#10b981"
            cornerRadius: 24
            padding: 22
            borderTone: "#dfe8ef"

            Column {
                width: parent.width
                spacing: 12

                Label {
                    text: "Custom instructions"
                    color: "#163042"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 24
                    font.weight: Font.Black
                }

                Label {
                    width: parent.width
                    text: "Keep this short and specific. Good examples: preserve bullet structure, keep email replies concise, or protect technical jargon exactly."
                    color: "#627b8e"
                    font.family: "Segoe UI Variable Text"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 188
                    radius: 20
                    color: "#ffffff"
                    border.width: 1
                    border.color: "#dce7ed"

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 14
                        text: root.customPromptDraft
                        color: "#163042"
                        wrapMode: TextEdit.Wrap
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        background: null
                        placeholderText: "Example: Prefer short paragraphs. Preserve product names exactly. Keep technical flags and commands unchanged."
                        placeholderTextColor: "#8ca0af"
                        onTextChanged: root.customPromptDraft = text
                    }
                }
            }
        }
    }
}
