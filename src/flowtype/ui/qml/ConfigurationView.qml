import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property bool showApiKey: false
    property string providerDraft: AppController.provider
    property string apiKeyDraft: AppController.apiKey
    property string modelDraft: AppController.model
    property string promptDraft: AppController.prompt
    property string pasteMethodDraft: AppController.pasteMethod
    property bool restoreClipboardDraft: AppController.restoreClipboard
    readonly property var providerModels: AppController.availableModelCards(providerDraft)
    readonly property bool providerNeedsKey: providerDraft !== "none" && providerDraft !== "ollama"

    function syncModelForProvider() {
        if (providerDraft === "none") {
            modelDraft = ""
            return
        }
        for (var i = 0; i < providerModels.length; i += 1) {
            if (providerModels[i].identifier === modelDraft)
                return
        }
        modelDraft = providerModels.length > 0 ? providerModels[0].identifier : ""
    }

    function modelIndex() {
        for (var i = 0; i < providerModels.length; i += 1) {
            if (providerModels[i].identifier === modelDraft)
                return i
        }
        return providerModels.length > 0 ? 0 : -1
    }

    function selectedModelCard() {
        var index = modelIndex()
        if (index < 0 || index >= providerModels.length)
            return null
        return providerModels[index]
    }

    function selectedProviderCard() {
        var cards = AppController.providerCards
        for (var i = 0; i < cards.length; i += 1) {
            if (cards[i].identifier === providerDraft)
                return cards[i]
        }
        return null
    }

    Connections {
        target: AppController

        function onConfigChanged() {
            root.providerDraft = AppController.provider
            root.apiKeyDraft = AppController.apiKey
            root.modelDraft = AppController.model
            root.promptDraft = AppController.prompt
            root.pasteMethodDraft = AppController.pasteMethod
            root.restoreClipboardDraft = AppController.restoreClipboard
            root.syncModelForProvider()
        }
    }

    onProviderDraftChanged: syncModelForProvider()

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 1240
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            SectionHeader {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                title: "Cleanup provider and model selection"
                subtitle: "Transcription stays local. Cleanup is optional, uses your own key, and can fall back to the raw transcript automatically."

                trailing: FlowButton {
                    label: "Save Cleanup"
                    variant: "primary"
                    accent: theme.primary
                    onClicked: AppController.saveCleanupSettings(
                        root.providerDraft,
                        root.apiKeyDraft,
                        root.modelDraft,
                        root.promptDraft,
                        root.pasteMethodDraft,
                        root.restoreClipboardDraft
                    )
                }
            }

            GridLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 76
                columns: 3
                columnSpacing: theme.space12
                rowSpacing: theme.space12

                Repeater {
                    model: AppController.providerCards

                    delegate: ChoiceCard {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        title: modelData.label
                        subtitle: modelData.summary
                        badge: modelData.badge
                        providerId: modelData.identifier
                        accent: modelData.accent
                        selected: root.providerDraft === modelData.identifier
                        onClicked: root.providerDraft = modelData.identifier
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: root.providerNeedsKey ? "API key" : "Connection"
                    subtitle: root.providerDraft === "ollama"
                        ? "FlowType will use the default local Ollama endpoint at http://localhost:11434."
                        : "A saved key or matching environment variable enables cleanup immediately."
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    spacing: theme.space12

                    InputSurface {
                        width: parent.width
                        height: 52

                        RowLayout {
                            anchors.fill: parent
                            spacing: theme.space12

                            TextField {
                                Layout.fillWidth: true
                                text: root.apiKeyDraft
                                color: theme.textPrimary
                                echoMode: root.showApiKey ? TextInput.Normal : TextInput.Password
                                placeholderText: root.providerDraft === "none"
                                    ? "No key needed for local-only mode"
                                    : (root.providerDraft === "ollama"
                                        ? "No API key required for a local Ollama instance"
                                        : "Paste your " + (root.selectedProviderCard() === null ? "provider" : root.selectedProviderCard().label) + " API key")
                                placeholderTextColor: theme.textTertiary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textBody
                                background: null
                                readOnly: !root.providerNeedsKey
                                onTextChanged: root.apiKeyDraft = text
                            }

                            FlowButton {
                                visible: root.providerNeedsKey
                                label: root.showApiKey ? "Hide" : "Show"
                                variant: "secondary"
                                compact: true
                                onClicked: root.showApiKey = !root.showApiKey
                            }
                        }
                    }

                    Label {
                        visible: root.providerDraft === "gemini"
                        width: parent.width
                        text: "Gemini also supports GEMINI_API_KEY or GOOGLE_API_KEY as an environment fallback."
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textHelper
                        wrapMode: Text.WordWrap
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 360

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Cleanup model"
                    subtitle: root.providerDraft === "openrouter"
                        ? "Shows maintained current free and paid picks."
                        : "Use the maintained current model list for this provider."
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    spacing: theme.space12

                    FlowModelCombo {
                        width: parent.width
                        model: root.providerModels
                        currentIndex: root.modelIndex()
                        selectedCard: root.selectedModelCard()
                        placeholderText: "Select a model"
                        onOptionPicked: (index) => root.modelDraft = root.providerModels[index].identifier
                    }

                    Label {
                        width: parent.width
                        visible: root.providerModels.length === 0
                        text: "No curated model list for this provider yet. Use a manual model ID below."
                        color: theme.textTertiary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textHelper
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        width: parent.width
                        visible: root.providerModels.length > 0
                        text: "Use Custom model ID below for any exact model not shown here."
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textHelper
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: theme.space16
            visible: root.providerDraft !== "none"

            SectionCard {
                Layout.fillWidth: true

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Custom model ID"
                    subtitle: "Optional override if you know the exact model identifier."
                }

                InputSurface {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    height: 52

                    TextField {
                        anchors.fill: parent
                        text: root.modelDraft
                        color: theme.textPrimary
                        placeholderText: "e.g. openai/gpt-4.1-mini or deepseek/deepseek-r1-0528"
                        placeholderTextColor: theme.textTertiary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textBody
                        background: null
                        onTextChanged: root.modelDraft = text
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 340

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Paste behavior"
                    subtitle: "Choose whether FlowType pastes immediately or only copies to the clipboard."
                }

                Row {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 74
                    spacing: theme.space8

                    ChoiceCard {
                        width: 148
                        compact: true
                        hideChevron: true
                        title: "Paste into app"
                        selected: root.pasteMethodDraft === "ctrl_v"
                        accent: theme.primary
                        onClicked: root.pasteMethodDraft = "ctrl_v"
                    }

                    ChoiceCard {
                        width: 136
                        compact: true
                        hideChevron: true
                        title: "Clipboard only"
                        selected: root.pasteMethodDraft === "clipboard_only"
                        accent: theme.primary
                        onClicked: root.pasteMethodDraft = "clipboard_only"
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
                title: "Cleanup prompt"
                subtitle: "This prompt is combined with the active mode and your vocabulary. Keep it short and focused on cleanup behavior."
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 74
                spacing: theme.space12

                Rectangle {
                    width: parent.width
                    height: 188
                    radius: theme.radiusCard
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.border

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 14
                        text: root.promptDraft
                        color: theme.textPrimary
                        wrapMode: TextEdit.Wrap
                        font.family: theme.fontUi
                        font.pixelSize: theme.textBody
                        background: null
                        placeholderText: "Return only the cleaned dictated text. Remove filler words when they are verbal fillers. Fix punctuation and grammar without changing meaning."
                        placeholderTextColor: theme.textTertiary
                        onTextChanged: root.promptDraft = text
                    }
                }

                FormRow {
                    width: parent.width
                    title: "Restore clipboard after paste"
                    detail: "Turn this on if you want FlowType to restore the previous clipboard contents after auto-paste."

                    FlowSwitch {
                        checked: root.restoreClipboardDraft
                        onToggled: root.restoreClipboardDraft = checked
                    }
                }
            }
        }
    }
}
