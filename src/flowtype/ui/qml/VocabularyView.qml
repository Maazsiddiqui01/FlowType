import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string vocabularyDraft: AppController.vocabularyText

    function parsedEntries() {
        if (root.vocabularyDraft.length === 0)
            return []
        return root.vocabularyDraft
            .split(/\r?\n/)
            .map(function(entry) { return entry.trim() })
            .filter(function(entry) { return entry.length > 0 })
    }

    Connections {
        target: AppController

        function onConfigChanged() {
            root.vocabularyDraft = AppController.vocabularyText
        }
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1160
        contentSpacing: 20

        SurfacePanel {
            width: parent.width
            prominent: true
            accent: "#10b981"
            cornerRadius: 28
            padding: 24
            borderTone: "#dfe8ef"

            RowLayout {
                width: parent.width
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Vocabulary that survives transcription and cleanup"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 29
                        font.weight: Font.Black
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Add names, acronyms, company jargon, and spoken-to-written replacements. These entries feed directly into the cleanup prompt."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                FlowButton {
                    label: "Save Vocabulary"
                    variant: "success"
                    onClicked: AppController.saveVocabulary(root.vocabularyDraft)
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: 18

            SurfacePanel {
                Layout.fillWidth: true
                accent: "#10b981"
                cornerRadius: 24
                padding: 20
                borderTone: "#dfe8ef"

                Column {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: "Dictionary"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 24
                        font.weight: Font.Black
                    }

                    Rectangle {
                        width: parent.width
                        height: 320
                        radius: 22
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#dce7ed"

                        TextArea {
                            anchors.fill: parent
                            anchors.margins: 14
                            text: root.vocabularyDraft
                            wrapMode: TextEdit.Wrap
                            color: "#173042"
                            font.family: "Cascadia Code"
                            font.pixelSize: 13
                            background: null
                            placeholderText: "FlowType\nOpenRouter\n1Password\nvisual studio code => VS Code\nanti gravity => AntiGravity"
                            placeholderTextColor: "#8ca0af"
                            onTextChanged: root.vocabularyDraft = text
                        }
                    }
                }
            }

            SurfacePanel {
                Layout.preferredWidth: 320
                accent: "#3b82f6"
                cornerRadius: 24
                padding: 20
                borderTone: "#dfe8ef"

                Column {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: "Preview"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 24
                        font.weight: Font.Black
                    }

                    Label {
                        width: parent.width
                        text: root.parsedEntries().length === 0
                            ? "Add a few terms and they will appear here as reusable cleanup cues."
                            : "These entries are appended after the base cleanup prompt and the active mode."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.parsedEntries()

                            delegate: Rectangle {
                                visible: index < 12
                                radius: 14
                                color: "#f4f8fb"
                                border.width: 1
                                border.color: "#dce7ed"
                                implicitWidth: previewText.implicitWidth + 20
                                implicitHeight: 34

                                Label {
                                    id: previewText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "#173042"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#e6eef3"
                    }

                    Repeater {
                        model: [
                            "Use exact product names and team names.",
                            "Add casing-sensitive acronyms you care about.",
                            "Use replacements for terms Whisper often misses."
                        ]

                        delegate: RowLayout {
                            width: parent.width
                            spacing: 10

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: index === 0 ? "#10b981" : (index === 1 ? "#3b82f6" : "#f97316")
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData
                                color: "#627b8e"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
