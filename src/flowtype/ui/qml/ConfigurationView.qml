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
        if (index < 0 || index >= providerModels.length) return null
        return providerModels[index]
    }

    function selectedProviderCard() {
        var cards = AppController.providerCards
        for (var i = 0; i < cards.length; i += 1) {
            if (cards[i].identifier === providerDraft) return cards[i]
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
        maxContentWidth: 1060
        contentSpacing: theme.sectionGap

        // ── Header Actions ───────────────────────────────
        Item {
            width: parent.width
            height: headLabel.implicitHeight

            Label {
                id: headLabel
                text: "Cleanup Configuration"
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizePageTitle
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            FlowButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                label: "Save Changes"
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

        // ── Provider Selection ───────────────────────────
        SectionCard {
            width: parent.width
            
            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Provider"
                    subtitle: "Select the API provider to clean and format transcribed text."
                }

                GridLayout {
                    width: parent.width
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
                            providerId: modelData.identifier
                            accent: modelData.accent
                            selected: root.providerDraft === modelData.identifier
                            onClicked: root.providerDraft = modelData.identifier
                        }
                    }
                }
            }
        }

        // ── Model & API Keys ─────────────────────────────
        RowLayout {
            width: parent.width
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                Column {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: root.providerNeedsKey ? "API Key" : "Connection details"
                        subtitle: root.providerDraft === "ollama" 
                            ? "Uses default localhost:11434" 
                            : "Enter your private key for this provider."
                    }

                    InputSurface {
                        width: parent.width
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            spacing: theme.space8

                            TextField {
                                Layout.fillWidth: true
                                text: root.apiKeyDraft
                                color: theme.textPrimary
                                echoMode: root.showApiKey ? TextInput.Normal : TextInput.Password
                                placeholderText: root.providerDraft === "none" || root.providerDraft === "ollama"
                                    ? "Not required"
                                    : "Paste your API key here..."
                                placeholderTextColor: theme.textTertiary
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeBody
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

                    Row {
                        spacing: theme.space8
                        visible: root.providerNeedsKey

                        Label {
                            text: "Don't have one?"
                            color: theme.textSecondary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeHelper
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: "Get a " + (root.selectedProviderCard() !== null ? root.selectedProviderCard().label : "provider") + " key"
                            color: theme.primary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeHelper
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AppController.openProviderKeyPage(root.providerDraft)
                            }
                        }
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                Column {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Cleanup Model"
                        subtitle: "Select the specific language model version to use."
                    }

                    FlowModelCombo {
                        width: parent.width
                        modelCards: root.providerModels
                        currentIndex: root.modelIndex()
                        onActivated: (index) => root.modelDraft = root.providerModels[index].identifier
                    }
                    
                    // Fallback specific custom text entry if the list is missing/empty
                    InputSurface {
                        width: parent.width
                        height: 48
                        visible: root.providerDraft !== "none" && root.providerModels.length === 0
                        
                        TextField {
                            anchors.fill: parent
                            text: root.modelDraft
                            color: theme.textPrimary
                            placeholderText: "e.g. gpt-4o-mini"
                            placeholderTextColor: theme.textTertiary
                            font.family: theme.fontUi
                            font.pixelSize: theme.sizeBody
                            background: null
                            onTextChanged: root.modelDraft = text
                        }
                    }
                }
            }
        }

        // ── Prompts and behavior ─────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Base Instructions"
                    subtitle: "This is the core prompt applied to every dictation. Use modes (presets) for specific workflow tweaks instead of changing this often."
                }

                Rectangle {
                    width: parent.width
                    height: 180
                    radius: theme.radiusControl
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
                        font.pixelSize: theme.sizeBody
                        background: null
                        onTextChanged: root.promptDraft = text
                    }
                }
            }
        }

        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space8

                FormRow {
                    title: "Action after cleanup"
                    subtitle: "Choose if the app should immediately paste or only copy."

                    Row {
                        spacing: 8
                        FlowButton {
                            label: "Type out (Ctrl+V)"
                            compact: true
                            variant: root.pasteMethodDraft === "ctrl_v" ? "primary" : "secondary"
                            // accent: theme.teal
                            onClicked: root.pasteMethodDraft = "ctrl_v"
                        }
                        FlowButton {
                            label: "Clipboard only"
                            compact: true
                            variant: root.pasteMethodDraft === "clipboard_only" ? "primary" : "secondary"
                            // accent: theme.teal
                            onClicked: root.pasteMethodDraft = "clipboard_only"
                        }
                    }
                }
                
                Rectangle { width: parent.width; height: 1; color: theme.divider }

                FormRow {
                    title: "Restore prior clipboard"
                    subtitle: "Revert the clipboard contents back to what it was before your dictation paste occurred."

                    FlowSwitch {
                        checked: root.restoreClipboardDraft
                        onClicked: root.restoreClipboardDraft = checked
                    }
                }
            }
        }
    }
}
