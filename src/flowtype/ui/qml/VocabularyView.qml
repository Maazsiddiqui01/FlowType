import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

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
        contentSpacing: theme.sectionGap

        RowLayout {
            width: parent.width
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Dictionary"
                    subtitle: "Add names, acronyms, company jargon, and spoken-to-written replacements."

                    trailing: FlowButton {
                        label: "Save Vocabulary"
                        variant: "success"
                        onClicked: AppController.saveVocabulary(root.vocabularyDraft)
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    height: 360
                    radius: theme.radiusCard
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.border

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 14
                        text: root.vocabularyDraft
                        wrapMode: TextEdit.Wrap
                        color: theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.textBody
                        background: null
                        placeholderText: "FlowType\nOpenRouter\n1Password\nvisual studio code => VS Code\nanti gravity => AntiGravity"
                        placeholderTextColor: theme.textTertiary
                        onTextChanged: root.vocabularyDraft = text
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 332

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Preview"
                    subtitle: root.parsedEntries().length === 0
                        ? "Add a few terms and they will appear here as reusable cleanup cues."
                        : "These entries are appended after the base cleanup prompt and the active mode."
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    spacing: theme.space12

                    Flow {
                        width: parent.width
                        spacing: theme.space8

                        Repeater {
                            model: root.parsedEntries()

                            delegate: TokenChip {
                                visible: index < 12
                                label: modelData
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: theme.divider
                    }

                    Repeater {
                        model: [
                            "Use exact product names and team names.",
                            "Add casing-sensitive acronyms you care about.",
                            "Use replacements for terms Whisper often misses."
                        ]

                        delegate: RowLayout {
                            width: parent.width
                            spacing: theme.space8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: index === 0 ? theme.teal : (index === 1 ? theme.primary : theme.warm)
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 5
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData
                                color: theme.textSecondary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textBody
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
