import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

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
        color: "#edf4f7"
        opacity: root.modalVisible ? 0.92 : 0.0

        Behavior on opacity { NumberAnimation { duration: 170 } }

        MouseArea {
            anchors.fill: parent
            enabled: root.modalVisible
        }
    }

    SurfacePanel {
        id: modalCard
        width: Math.min(parent.width - 90, 980)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        cornerRadius: 32
        prominent: true
        accent: "#2563eb"
        padding: 28
        visible: overlay.opacity > 0.01
        opacity: root.modalVisible ? 1.0 : 0.0
        scale: root.modalVisible ? 1.0 : 0.98

        Behavior on opacity { NumberAnimation { duration: 170 } }
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        Column {
            width: parent.width
            spacing: 18

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: ["Local transcription works immediately", "Cleanup is optional", "Everything can change later"]

                    delegate: Rectangle {
                        radius: 14
                        color: "#f2f7fb"
                        border.width: 1
                        border.color: "#dde8ef"
                        implicitWidth: chipLabel.implicitWidth + 20
                        implicitHeight: 32

                        Label {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: "#36566c"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "Set FlowType up once, then get out of the way"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 34
                        font.weight: Font.Black
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Choose a cleanup provider if you want punctuation polish and filler removal, or skip and stay fully local for now."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 18

                SurfacePanel {
                    Layout.fillWidth: true
                    accent: "#2563eb"
                    cornerRadius: 24
                    padding: 20

                    Column {
                        width: parent.width
                        spacing: 12

                        Label {
                            text: "1. Choose cleanup"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 24
                            font.weight: Font.Black
                        }

                        Flow {
                            width: parent.width
                            spacing: 12

                            Repeater {
                                model: AppController.featuredProviderCards

                                delegate: Rectangle {
                                    width: (parent.width - 20) / 3
                                    height: 96
                                    radius: 18
                                    color: root.providerDraft === modelData.identifier ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.12) : "#ffffff"
                                    border.width: 1
                                    border.color: root.providerDraft === modelData.identifier ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.42) : "#dce7ed"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 10

                                        ProviderBadge {
                                            badge: modelData.badge
                                            accent: modelData.accent
                                            badgeBackground: modelData.badgeBackground
                                            badgeForeground: modelData.badgeForeground
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Label {
                                                text: modelData.label
                                                color: "#173042"
                                                font.family: "Segoe UI Variable Text"
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }

                                            Label {
                                                text: modelData.summary
                                                color: "#627b8e"
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

                        Rectangle {
                            visible: root.providerDraft !== "none"
                            width: parent.width
                            height: 74
                            radius: 18
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#dce7ed"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
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
                                        placeholderText: root.providerDraft === "ollama"
                                            ? "No API key required for a local Ollama instance"
                                            : "Paste your " + (root.selectedProviderCard() === null ? "provider" : root.selectedProviderCard().label) + " API key"
                                        placeholderTextColor: "#8ca0af"
                                        font.family: "Segoe UI Variable Text"
                                        font.pixelSize: 13
                                        background: null
                                        readOnly: !root.providerNeedsKey
                                        onTextChanged: root.apiKeyDraft = text
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

                        Rectangle {
                            visible: root.providerDraft !== "none"
                            width: parent.width
                            height: 116
                            radius: 18
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#dce7ed"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                Label {
                                    text: "Cleanup model"
                                    color: "#6a8496"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                }

                                FlowModelCombo {
                                    id: onboardingModelCombo
                                    Layout.fillWidth: true
                                    model: root.providerModels
                                    currentIndex: root.modelIndex()
                                    selectedCard: root.selectedModelCard()
                                    placeholderText: "Select a cleanup model"
                                    onOptionPicked: (index) => root.modelDraft = root.providerModels[index].identifier
                                }

                                Label {
                                    visible: root.providerModels.length > 0
                                    Layout.fillWidth: true
                                    text: root.providerDraft === "openrouter"
                                        ? "Shows current maintained free and paid picks. Use Settings later if you want a manual model ID."
                                        : "Shows the maintained current model list for this provider."
                                    color: "#60788a"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                SurfacePanel {
                    Layout.preferredWidth: 310
                    accent: "#0d9488"
                    cornerRadius: 24
                    padding: 20

                    Column {
                        width: parent.width
                        spacing: 12

                        Label {
                            text: "2. Pick dictation language"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 24
                            font.weight: Font.Black
                        }

                        Repeater {
                            model: AppController.transcriptionLanguageCards

                            delegate: Rectangle {
                                width: parent.width
                                height: 68
                                radius: 18
                                color: root.languageDraft === modelData.code ? Qt.rgba(13 / 255, 148 / 255, 136 / 255, 0.12) : "#ffffff"
                                border.width: 1
                                border.color: root.languageDraft === modelData.code ? "#67d1c5" : "#dce7ed"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 4

                                    Label {
                                        text: modelData.label
                                        color: "#173042"
                                        font.family: "Segoe UI Variable Text"
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                    }

                                    Label {
                                        width: parent.width
                                        text: modelData.summary
                                        color: "#627b8e"
                                        font.family: "Segoe UI Variable Text"
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.languageDraft = modelData.code
                                }
                            }
                        }
                    }
                }
            }

            SurfacePanel {
                width: parent.width
                accent: "#6366f1"
                cornerRadius: 24
                padding: 18

                RowLayout {
                    width: parent.width
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "3. Keep FlowType ready after login"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 22
                            font.weight: Font.Black
                        }

                        Label {
                            text: "Recommended for the beta: start with Windows so the global dictation shortcut is already available when your desktop loads. FlowType will start minimized in the tray."
                            color: "#627b8e"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    FlowSwitch {
                        checked: root.launchAtLoginDraft
                        onToggled: (checked) => root.launchAtLoginDraft = checked
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#e7eff4"
            }

            RowLayout {
                width: parent.width
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Local transcription already works. Cleanup turns on as soon as the provider settings are saved."
                        color: "#173042"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "You can change providers, models, startup behavior, language, and shortcuts later inside Settings."
                        color: "#72879a"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 12
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
                    accent: "#2563eb"
                    buttonEnabled: root.canContinue
                    onClicked: AppController.completeOnboarding(root.providerDraft, root.apiKeyDraft, root.modelDraft, root.languageDraft, root.launchAtLoginDraft)
                }
            }
        }
    }
}
