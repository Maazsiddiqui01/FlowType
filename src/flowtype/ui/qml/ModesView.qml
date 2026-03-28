import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string selectedMode: AppController.activeMode
    property string customPromptDraft: AppController.customModePrompt

    function selectedModeCard() {
        for (var i = 0; i < AppController.modeCards.length; i += 1) {
            if (AppController.modeCards[i].identifier === root.selectedMode)
                return AppController.modeCards[i]
        }
        return AppController.modeCards.length > 0 ? AppController.modeCards[0] : null
    }

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
                    title: "Modes"
                    subtitle: "Pick one active preset for the way you usually work. Keep custom notes short and specific."
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    spacing: theme.space12

                    Repeater {
                        model: AppController.modeCards

                        delegate: ChoiceCard {
                            width: parent.width
                            title: modelData.label
                            subtitle: modelData.summary
                            badge: modelData.label.slice(0, 1).toUpperCase()
                            accent: modelData.accent
                            selected: root.selectedMode === modelData.identifier
                            onClicked: root.selectedMode = modelData.identifier
                        }
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 360

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: root.selectedModeCard() === null ? "Selected mode" : root.selectedModeCard().label
                    subtitle: root.selectedModeCard() === null ? "" : root.selectedModeCard().summary
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    spacing: theme.space12

                    Repeater {
                        model: [
                            "Base cleanup prompt",
                            "Selected mode preset",
                            "Your custom notes",
                            "Vocabulary entries"
                        ]

                        delegate: FormRow {
                            width: parent.width
                            title: modelData
                            detail: index === 1
                                ? "This mode contributes its preset intent before the final LLM cleanup call."
                                : ""

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: index === 0 ? theme.primary : (index === 1 ? theme.teal : (index === 2 ? theme.warm : theme.error))
                            }
                        }
                    }
                }
            }
        }

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Custom instructions"
                subtitle: "Good examples: preserve bullet structure, keep email replies concise, or protect technical jargon exactly."

                trailing: FlowButton {
                    label: "Save Mode"
                    variant: "primary"
                    accent: theme.primary
                    onClicked: AppController.saveModeSettings(root.selectedMode, root.customPromptDraft)
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 74
                height: 206
                radius: theme.radiusCard
                color: theme.surfaceSubtle
                border.width: 1
                border.color: theme.border

                TextArea {
                    anchors.fill: parent
                    anchors.margins: 14
                    text: root.customPromptDraft
                    color: theme.textPrimary
                    wrapMode: TextEdit.Wrap
                    font.family: theme.fontUi
                    font.pixelSize: theme.textBody
                    background: null
                    placeholderText: "Example: Prefer short paragraphs. Preserve product names exactly. Keep technical flags and commands unchanged."
                    placeholderTextColor: theme.textTertiary
                    onTextChanged: root.customPromptDraft = text
                }
            }
        }
    }
}
