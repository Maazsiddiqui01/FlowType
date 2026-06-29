import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string selectedMode: AppController.activeMode
    property string customPromptDraft: AppController.customModePrompt
    property string appRulesDraft: AppController.appRules

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
            root.appRulesDraft = AppController.appRules
        }
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1180
        contentSpacing: theme.sectionGap

        // ── Learned per-app suggestion ───────────────────────────────────────
        Rectangle {
            width: parent.width
            visible: AppController.modeSuggestionApp.length > 0
            implicitHeight: suggestionCol.implicitHeight + theme.space20 * 2
            radius: theme.radiusCard
            color: theme.tint(theme.primary, theme.darkMode ? 0.16 : 0.10)
            border.width: 1
            border.color: theme.tint(theme.primary, theme.darkMode ? 0.45 : 0.30)

            ColumnLayout {
                id: suggestionCol
                anchors.fill: parent
                anchors.margins: theme.space20
                spacing: theme.space12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: theme.space12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: "Auto-apply a mode for " + AppController.modeSuggestionApp + "?"
                            color: theme.textPrimary
                            font.family: theme.fontDisplay
                            font.pixelSize: theme.sizeSectionTitle
                            font.weight: 700
                        }
                        Label {
                            Layout.fillWidth: true
                            text: "You've dictated into this app a few times. Pick a mode and FlowType will switch to it automatically whenever " + AppController.modeSuggestionApp + " is in front."
                            color: theme.textSecondary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeHelper
                            wrapMode: Text.WordWrap
                        }
                    }

                    FlowButton {
                        Layout.alignment: Qt.AlignTop
                        label: "Dismiss"
                        variant: "ghost"
                        compact: true
                        onClicked: AppController.dismissModeSuggestion()
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: theme.space8

                    Repeater {
                        model: AppController.modeCards

                        delegate: FlowButton {
                            label: modelData.label
                            variant: "secondary"
                            compact: true
                            onClicked: AppController.applyAppModeSuggestion(modelData.identifier)
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space12

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1.4

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Available modes"
                        subtitle: "Choose one preset to shape cleanup for your usual work style."
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.space12

                        Repeater {
                            model: AppController.modeCards

                            delegate: ChoiceCard {
                                Layout.fillWidth: true
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
            }

            SectionCard {
                Layout.preferredWidth: 360
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: root.selectedModeCard() ? root.selectedModeCard().label : "Selected mode"
                        subtitle: root.selectedModeCard() ? root.selectedModeCard().summary : ""
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "This mode is layered on top of the base cleanup prompt and vocabulary before the final cleanup call."
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeBody
                        wrapMode: Text.WordWrap
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.space10

                        Repeater {
                            model: [
                                { "title": "Base cleanup prompt", "tone": theme.primary },
                                { "title": "Mode preset", "tone": theme.teal },
                                { "title": "Custom notes", "tone": theme.warm },
                                { "title": "Vocabulary rules", "tone": theme.error }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 44
                                radius: theme.radiusControl
                                color: theme.surfaceSubtle
                                border.width: 1
                                border.color: theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: theme.space12
                                    anchors.rightMargin: theme.space12
                                    spacing: theme.space12

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: modelData.tone
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: theme.textPrimary
                                        font.family: theme.fontUi
                                        font.pixelSize: theme.sizeBody
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        SectionCard {
            width: parent.width

            ColumnLayout {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Custom instructions"
                    subtitle: "Keep this short and concrete. Use it for workflow-specific rules that do not belong in the global cleanup prompt."

                    trailing: FlowButton {
                        label: "Save Mode"
                        variant: "primary"
                        onClicked: AppController.saveModeSettings(root.selectedMode, root.customPromptDraft)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    radius: theme.radiusCard
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.border

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: theme.space16
                        text: root.customPromptDraft
                        color: theme.textPrimary
                        wrapMode: TextEdit.Wrap
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeBody
                        background: null
                        placeholderText: "Example: Keep product names exact. Prefer short paragraphs. Preserve code flags and filenames verbatim."
                        placeholderTextColor: theme.textTertiary
                        onTextChanged: root.customPromptDraft = text
                    }
                }
            }
        }

        SectionCard {
            width: parent.width

            ColumnLayout {
                width: parent.width
                spacing: theme.space12

                SectionHeader {
                    title: "Per-app modes"
                    subtitle: "Auto-switch cleanup mode based on the app you are dictating into. One rule per line, format: app or window text = mode."

                    trailing: FlowButton {
                        label: "Save Rules"
                        variant: "primary"
                        onClicked: AppController.saveAppRules(root.appRulesDraft)
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: {
                        var ids = []
                        for (var i = 0; i < AppController.modeCards.length; i += 1)
                            ids.push(AppController.modeCards[i].identifier)
                        return "Available modes: " + ids.join(", ") + ". Example: code.exe = technical"
                    }
                    color: theme.textTertiary
                    font.family: theme.fontUi
                    font.pixelSize: theme.sizeHelper
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    radius: theme.radiusCard
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.border

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: theme.space16
                        text: root.appRulesDraft
                        color: theme.textPrimary
                        wrapMode: TextEdit.Wrap
                        font.family: theme.fontMono
                        font.pixelSize: theme.sizeBody
                        background: null
                        placeholderText: "code.exe = technical\nslack.exe = default\noutlook.exe = meeting\nWord = focused"
                        placeholderTextColor: theme.textTertiary
                        onTextChanged: root.appRulesDraft = text
                    }
                }
            }
        }
    }
}
