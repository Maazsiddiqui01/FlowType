import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    anchors.fill: parent
    visible: AppController.onboardingVisible || overlay.opacity > 0

    property string providerDraft: AppController.provider === "none" ? "openrouter" : AppController.provider
    property string apiKeyDraft: AppController.apiKey
    property string modelDraft: AppController.model
    property string languageDraft: AppController.transcriptionLanguage
    property bool launchAtLoginDraft: AppController.startupPromptCompleted ? AppController.launchAtLogin : true
    property bool showApiKey: false
    readonly property bool modalVisible: AppController.onboardingVisible
    readonly property bool providerNeedsKey: providerDraft !== "none" && providerDraft !== "ollama"
    readonly property bool canContinue: !providerNeedsKey || apiKeyDraft.trim().length > 0
    readonly property var providerModels: AppController.availableModelCards(providerDraft)

    function syncFromController() {
        providerDraft = AppController.provider === "none" ? "openrouter" : AppController.provider
        apiKeyDraft = AppController.apiKey
        languageDraft = AppController.transcriptionLanguage
        launchAtLoginDraft = AppController.startupPromptCompleted ? AppController.launchAtLogin : true
        syncModelForProvider()
    }

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
        var cards = AppController.featuredProviderCards
        for (var i = 0; i < cards.length; i += 1) {
            if (cards[i].identifier === providerDraft)
                return cards[i]
        }
        return null
    }

    Component.onCompleted: syncFromController()
    onProviderDraftChanged: syncModelForProvider()

    Connections {
        target: AppController

        function onConfigChanged() {
            if (root.modalVisible)
                root.syncFromController()
        }
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#F1F6FA"
        opacity: root.modalVisible ? 0.94 : 0.0

        Behavior on opacity { NumberAnimation { duration: 170 } }

        MouseArea {
            anchors.fill: parent
            enabled: root.modalVisible
        }
    }

    SectionCard {
        id: modalCard
        width: Math.min(parent.width - 80, 1040)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        padding: theme.cardPaddingLarge
        cornerRadius: 28
        visible: overlay.opacity > 0.01
        opacity: root.modalVisible ? 1.0 : 0.0
        scale: root.modalVisible ? 1.0 : 0.98

        Behavior on opacity { NumberAnimation { duration: 170 } }
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        Column {
            width: parent.width
            spacing: theme.sectionGap

            Flow {
                width: parent.width
                spacing: theme.space8

                Repeater {
                    model: ["Local transcription works immediately", "Cleanup is optional", "Everything can change later"]

                    delegate: TokenChip {
                        label: modelData
                    }
                }
            }

            Column {
                width: parent.width
                spacing: theme.space8

                Label {
                    text: "Set FlowType up once, then get out of the way"
                    color: theme.textPrimary
                    font.family: theme.fontDisplay
                    font.pixelSize: 40
                    font.weight: Font.Black
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Label {
                    text: "Choose a cleanup provider if you want punctuation polish and filler removal, or skip and stay fully local for now."
                    color: theme.textSecondary
                    font.family: theme.fontUi
                    font.pixelSize: theme.textBody
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            RowLayout {
                width: parent.width
                spacing: theme.space16

                SectionCard {
                    Layout.fillWidth: true
                    baseColor: theme.surfaceSubtle

                    SectionHeader {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        title: "1. Choose cleanup"
                        subtitle: "Use your own provider key now, or skip and stay local for the first run."
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 74
                        spacing: theme.space12

                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: theme.space12
                            rowSpacing: theme.space12

                            Repeater {
                                model: AppController.featuredProviderCards

                                delegate: ChoiceCard {
                                    Layout.fillWidth: true
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

                        InputSurface {
                            visible: root.providerDraft !== "none"
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
                                    placeholderText: root.providerDraft === "ollama"
                                        ? "No API key required for a local Ollama instance"
                                        : "Paste your " + (root.selectedProviderCard() === null ? "provider" : root.selectedProviderCard().label) + " API key"
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

                        FlowModelCombo {
                            visible: root.providerDraft !== "none"
                            width: parent.width
                            model: root.providerModels
                            currentIndex: root.modelIndex()
                            selectedCard: root.selectedModelCard()
                            placeholderText: "Select a cleanup model"
                            onOptionPicked: (index) => root.modelDraft = root.providerModels[index].identifier
                        }
                    }
                }

                SectionCard {
                    Layout.preferredWidth: 332
                    baseColor: theme.surfaceSubtle

                    SectionHeader {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        title: "2. Pick dictation language"
                        subtitle: "Use a fixed language for the best speed and fewer bad guesses."
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 74
                        spacing: theme.space12

                        Repeater {
                            model: AppController.transcriptionLanguageCards

                            delegate: ChoiceCard {
                                width: parent.width
                                title: modelData.label
                                subtitle: modelData.summary
                                badge: modelData.code === "auto" ? "A" : modelData.code.toUpperCase()
                                accent: theme.teal
                                compact: true
                                selected: root.languageDraft === modelData.code
                                onClicked: root.languageDraft = modelData.code
                            }
                        }
                    }
                }
            }

            SectionCard {
                width: parent.width
                baseColor: theme.surfaceSubtle

                FormRow {
                    anchors.fill: parent
                    title: "3. Keep FlowType ready after login"
                    detail: "Recommended for the beta: start with Windows so the global dictation shortcut is already available when your desktop loads."

                    FlowSwitch {
                        checked: root.launchAtLoginDraft
                        onToggled: (checked) => root.launchAtLoginDraft = checked
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: theme.space12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Local transcription already works. Cleanup turns on as soon as the provider settings are saved."
                        color: theme.textPrimary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textBody
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "You can change providers, models, startup behavior, language, and shortcuts later inside Settings."
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textHelper
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                FlowButton {
                    label: "Use Local Only"
                    variant: "secondary"
                    onClicked: AppController.skipOnboarding(root.launchAtLoginDraft)
                }

                FlowButton {
                    label: "Enable Cleanup"
                    variant: "primary"
                    accent: theme.primary
                    buttonEnabled: root.canContinue
                    onClicked: AppController.completeOnboarding(root.providerDraft, root.apiKeyDraft, root.modelDraft, root.languageDraft, root.launchAtLoginDraft)
                }
            }
        }
    }
}
