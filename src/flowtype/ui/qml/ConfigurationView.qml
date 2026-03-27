import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

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
        maxContentWidth: 1220
        contentSpacing: 18

        SurfacePanel {
            width: parent.width
            prominent: true
            accent: "#2563eb"
            cornerRadius: 28
            padding: 22
            borderTone: "#dfe8ef"

            RowLayout {
                width: parent.width
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Cleanup provider and model selection"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 28
                        font.weight: Font.Black
                    }

                    Label {
                        text: "Transcription stays local. Cleanup is optional, uses your own key, and shows a maintained current model list plus manual override when you want an exact model ID."
                        color: "#4f697f"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                FlowButton {
                    label: "Save Cleanup"
                    variant: "primary"
                    accent: "#2563eb"
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
        }

        SurfacePanel {
            width: parent.width
            accent: "#2563eb"
            cornerRadius: 24
            padding: 20
            borderTone: "#dfe8ef"

            Column {
                width: parent.width
                spacing: 12

                Label {
                    text: "Providers"
                    color: "#163042"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 24
                    font.weight: Font.Black
                }

                Flow {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: AppController.providerCards

                        delegate: Rectangle {
                            width: (parent.width - 20) / 3
                            height: 100
                            radius: 18
                            color: root.providerDraft === modelData.identifier ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.12) : "#ffffff"
                            border.width: 1
                            border.color: root.providerDraft === modelData.identifier ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.48) : "#dce7ed"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                ProviderBadge {
                                    badge: modelData.badge
                                    accent: modelData.accent
                                    badgeBackground: modelData.badgeBackground
                                    badgeForeground: modelData.badgeForeground
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Label {
                                            text: modelData.label
                                            color: "#173042"
                                            font.family: "Segoe UI Variable Text"
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                        }

                                        Item { Layout.fillWidth: true }

                                        Label {
                                            text: root.providerDraft === modelData.identifier ? "Selected" : ""
                                            color: "#5d7b8d"
                                            font.family: "Bahnschrift SemiBold"
                                            font.pixelSize: 10
                                        }
                                    }

                                    Label {
                                        text: modelData.summary
                                        color: "#4f697f"
                                        font.family: "Segoe UI Variable Text"
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.providerDraft = modelData.identifier
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: 18

            SurfacePanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 118
                accent: "#0d9488"
                cornerRadius: 24
                padding: 18
                borderTone: "#dfe8ef"

                RowLayout {
                    anchors.fill: parent
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: root.providerNeedsKey ? "API key" : "Connection"
                            color: "#6a8496"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                        }

                        TextField {
                            Layout.fillWidth: true
                            text: root.apiKeyDraft
                            color: "#173042"
                            echoMode: root.showApiKey ? TextInput.Normal : TextInput.Password
                            placeholderText: root.providerDraft === "none"
                                ? "No key needed for local-only mode"
                                : (root.providerDraft === "ollama"
                                    ? "No API key required for a local Ollama instance"
                                    : "Paste your " + (root.selectedProviderCard() === null ? "provider" : root.selectedProviderCard().label) + " API key")
                            placeholderTextColor: "#8ca0af"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 13
                            background: null
                            readOnly: !root.providerNeedsKey
                            onTextChanged: root.apiKeyDraft = text
                        }

                        Label {
                            visible: root.providerDraft !== "none"
                            text: root.providerDraft === "gemini"
                                ? "Supports GEMINI_API_KEY or GOOGLE_API_KEY as an environment fallback."
                                : (root.providerDraft === "ollama"
                                    ? "FlowType will use the default local Ollama endpoint at http://localhost:11434."
                                    : "A saved key or matching environment variable enables cleanup immediately.")
                            color: "#72879a"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
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

            SurfacePanel {
                Layout.preferredWidth: 326
                Layout.preferredHeight: 146
                accent: "#2563eb"
                cornerRadius: 24
                padding: 18
                visible: root.providerDraft !== "none"
                borderTone: "#dfe8ef"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        text: "Cleanup model"
                        color: "#6a8496"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
                    }

                    FlowModelCombo {
                        id: modelCombo
                        Layout.fillWidth: true
                        model: root.providerModels
                        currentIndex: root.modelIndex()
                        selectedCard: root.selectedModelCard()
                        placeholderText: "Select a model"
                        onOptionPicked: (index) => root.modelDraft = root.providerModels[index].identifier
                    }

                    Label {
                        visible: root.providerModels.length === 0
                        text: "No curated model list for this provider yet. Use a manual model ID below."
                        color: "#72879a"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        visible: root.providerModels.length > 0
                        text: root.providerDraft === "openrouter"
                            ? "OpenRouter includes current free and paid model picks here. Use Custom model ID below for any exact model not shown."
                            : "Showing a maintained current model list for this provider. Use Custom model ID below if you need an exact override."
                        color: "#60788a"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        RowLayout {
            visible: root.providerDraft !== "none"
            width: parent.width
            spacing: 18

            SurfacePanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 82
                accent: "#2563eb"
                cornerRadius: 20
                padding: 14
                borderTone: "#dfe8ef"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Label {
                        text: "Custom model ID"
                        color: "#6a8496"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
                    }

                    TextField {
                        Layout.fillWidth: true
                        text: root.modelDraft
                        color: "#173042"
                        placeholderText: "Optional override if you know the exact model ID"
                        placeholderTextColor: "#8ca0af"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        background: null
                        onTextChanged: root.modelDraft = text
                    }
                }
            }

            SurfacePanel {
                Layout.preferredWidth: 300
                Layout.preferredHeight: 82
                accent: "#0d9488"
                cornerRadius: 20
                padding: 14
                borderTone: "#dfe8ef"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Label {
                        text: "Paste method"
                        color: "#6a8496"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
                    }

                    ComboBox {
                        Layout.fillWidth: true
                        model: [
                            { "label": "Paste into active app", "value": "ctrl_v" },
                            { "label": "Clipboard only", "value": "clipboard_only" }
                        ]
                        textRole: "label"
                        currentIndex: root.pasteMethodDraft === "clipboard_only" ? 1 : 0
                        onActivated: root.pasteMethodDraft = currentIndex === 1 ? "clipboard_only" : "ctrl_v"

                        background: Rectangle {
                            radius: 16
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#dce7ed"
                        }
                    }
                }
            }
        }

        SurfacePanel {
            width: parent.width
            accent: "#0d9488"
            cornerRadius: 24
            padding: 22
            borderTone: "#dfe8ef"

            Column {
                width: parent.width
                spacing: 12

                Label {
                    text: "Cleanup prompt"
                    color: "#163042"
                    font.family: "Segoe UI Variable Display"
                    font.pixelSize: 24
                    font.weight: Font.Black
                }

                Label {
                    width: parent.width
                    text: "This prompt is combined with the active mode and your vocabulary. Keep it short and focused on cleanup behavior."
                    color: "#627b8e"
                    font.family: "Segoe UI Variable Text"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 180
                    radius: 20
                    color: "#ffffff"
                    border.width: 1
                    border.color: "#dce7ed"

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 14
                        text: root.promptDraft
                        color: "#173042"
                        wrapMode: TextEdit.Wrap
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        background: null
                        placeholderText: "Return only the cleaned dictated text. Remove filler words when they are verbal fillers. Fix punctuation and grammar without changing meaning."
                        placeholderTextColor: "#8ca0af"
                        onTextChanged: root.promptDraft = text
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: "Restore clipboard after paste"
                        color: "#173042"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }

                    FlowSwitch {
                        checked: root.restoreClipboardDraft
                        onToggled: root.restoreClipboardDraft = checked
                    }
                }
            }
        }
    }
}
