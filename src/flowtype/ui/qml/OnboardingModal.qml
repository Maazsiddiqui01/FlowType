import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    Theme { id: theme }

    color: Qt.rgba(0, 0, 0, 0.7)
    visible: AppController.onboardingVisible

    property int step: 0
    property string providerDraft: "openrouter"
    property string apiKeyDraft: ""
    property string modelDraft: ""
    property string languageDraft: "en"
    property bool showApiKey: false

    readonly property var providerModels: AppController.availableModelCards(root.providerDraft)

    function syncModel() {
        for (var i = 0; i < providerModels.length; i += 1)
            if (providerModels[i].identifier === modelDraft) return
        modelDraft = providerModels.length > 0 ? providerModels[0].identifier : ""
    }
    onProviderDraftChanged: syncModel()
    Component.onCompleted: syncModel()

    function modelIndex() {
        for (var i = 0; i < providerModels.length; i += 1) {
            if (providerModels[i].identifier === modelDraft)
                return i
        }
        return providerModels.length > 0 ? 0 : -1
    }

    // Block clicks behind
    MouseArea { anchors.fill: parent; onClicked: {} }

    // ── Wizard card ──────────────────────────────────────
    Rectangle {
        id: wizardCard
        anchors.centerIn: parent
        width: Math.min(520, parent.width - 80)
        height: contentCol.implicitHeight + 80
        radius: 20
        color: theme.surface
        border.width: 1
        border.color: theme.border

        // Top highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: theme.glassHighlight
        }

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 36
            spacing: theme.space24

            // ── Step indicator ────────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: theme.space8

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: root.step === index ? 28 : 8
                        height: 8
                        radius: 4
                        color: root.step >= index ? theme.primary : theme.border

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            // ── Step 0: Welcome ──────────────────────────
            Column {
                visible: root.step === 0
                width: parent.width
                spacing: theme.space16

                Item { width: 1; height: theme.space8 }

                // Logo
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 16
                    color: theme.primary

                    Label {
                        anchors.centerIn: parent
                        text: "F"
                        color: "#ffffff"
                        font.family: theme.fontDisplay
                        font.pixelSize: 28
                        font.weight: Font.Bold
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Welcome to FlowType"
                    color: theme.textPrimary
                    font.family: theme.fontDisplay
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Dictate naturally. Get clean, ready-to-use text.\nTranscription runs locally. Cleanup uses your own API key."
                    color: theme.textSecondary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeBody
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }

                Item { width: 1; height: theme.space8 }

                FlowButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    label: "Get Started"
                    variant: "primary"
                    accent: theme.primary
                    onClicked: root.step = 1
                }
            }

            // ── Step 1: Provider setup ───────────────────
            Column {
                visible: root.step === 1
                width: parent.width
                spacing: theme.space16

                Label {
                    text: "Set up text cleanup"
                    color: theme.textPrimary
                    font.family: theme.fontDisplay
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                Label {
                    width: parent.width
                    text: "Choose a cleanup provider and paste your API key. This step is optional — you can skip and use local-only transcription."
                    color: theme.textSecondary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeBody
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                }

                // Provider selector
                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: theme.space8
                    rowSpacing: theme.space8

                    Repeater {
                        model: AppController.providerCards

                        delegate: ChoiceCard {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            visible: modelData.identifier !== "none"
                            title: modelData.label
                            subtitle: modelData.badge
                            providerId: modelData.identifier
                            accent: modelData.accent
                            selected: root.providerDraft === modelData.identifier
                            onClicked: root.providerDraft = modelData.identifier
                        }
                    }
                }

                // Get API Key link
                Label {
                    visible: root.providerDraft !== "none" && root.providerDraft !== "ollama"
                    text: "→ Get your " + root.providerDraft + " API key"
                    color: theme.primary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeBody
                    font.weight: Font.DemiBold

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppController.openProviderKeyPage(root.providerDraft)
                    }
                }

                // API key input
                Column {
                    width: parent.width
                    spacing: theme.space8
                    visible: root.providerDraft !== "none" && root.providerDraft !== "ollama"

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
                                placeholderText: "Paste your API key"
                                placeholderTextColor: theme.textTertiary
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeBody
                                background: null
                                onTextChanged: root.apiKeyDraft = text
                            }

                            FlowButton {
                                label: root.showApiKey ? "Hide" : "Show"
                                variant: "secondary"
                                compact: true
                                onClicked: root.showApiKey = !root.showApiKey
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: theme.space8
                    visible: root.providerDraft !== "none" && root.providerModels.length > 0

                    Label {
                        text: "Cleanup model"
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeHelper
                        font.weight: Font.Medium
                    }

                    FlowModelCombo {
                        width: parent.width
                        modelCards: root.providerModels
                        currentIndex: root.modelIndex()
                        onActivated: (index) => root.modelDraft = root.providerModels[index].identifier
                    }
                }

                // Language selection
                Label {
                    text: "Transcription language"
                    color: theme.textSecondary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeHelper
                    font.weight: Font.Medium
                }

                Flow {
                    width: parent.width
                    spacing: theme.space8

                    Repeater {
                        model: AppController.transcriptionLanguageCards

                        delegate: Rectangle {
                            width: langLabel.implicitWidth + 20
                            height: 32
                            radius: theme.radiusPill
                            color: root.languageDraft === modelData.code
                                ? theme.tint(theme.teal, 0.14)
                                : (theme.darkMode ? Qt.rgba(1,1,1,0.04) : Qt.rgba(0,0,0,0.04))
                            border.width: 1
                            border.color: root.languageDraft === modelData.code
                                ? theme.tint(theme.teal, 0.3)
                                : theme.border

                            Label {
                                id: langLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.languageDraft === modelData.code ? theme.teal : theme.textSecondary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeLabel
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.languageDraft = modelData.code
                            }
                        }
                    }
                }

                // Navigation
                RowLayout {
                    width: parent.width
                    spacing: theme.space12

                    FlowButton {
                        label: "Back"
                        variant: "secondary"
                        onClicked: root.step = 0
                    }

                    Item { Layout.fillWidth: true }

                    FlowButton {
                        label: "Skip — local only"
                        variant: "secondary"
                        onClicked: {
                            root.providerDraft = "none"
                            root.step = 2
                        }
                    }

                    FlowButton {
                        label: "Continue"
                        variant: "primary"
                        accent: theme.primary
                        onClicked: root.step = 2
                    }
                }
            }

            // ── Step 2: Confirm & launch ─────────────────
            Column {
                visible: root.step === 2
                width: parent.width
                spacing: theme.space16

                Item { width: 1; height: theme.space4 }

                Label {
                    text: "You're all set"
                    color: theme.textPrimary
                    font.family: theme.fontDisplay
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                Label {
                    width: parent.width
                    text: "Here's a summary of your setup. You can always change these later in Settings."
                    color: theme.textSecondary
                    font.family: theme.fontText
                    font.pixelSize: theme.sizeBody
                    wrapMode: Text.WordWrap
                }

                // Summary
                Column {
                    width: parent.width
                    spacing: theme.space8

                    Repeater {
                        model: [
                            { key: "Provider", val: root.providerDraft === "none" ? "None (local only)" : root.providerDraft },
                            { key: "Model", val: root.providerDraft === "none" ? "Raw transcript" : (root.modelDraft.length > 0 ? root.modelDraft : "Default") },
                            { key: "Language", val: root.languageDraft === "auto" ? "Auto-detect" : root.languageDraft.toUpperCase() },
                            { key: "API Key", val: root.providerDraft === "none" || root.providerDraft === "ollama" ? "Not required" : (root.apiKeyDraft.length > 0 ? "Configured ✓" : "Not set") }
                        ]

                        delegate: Rectangle {
                            width: parent.width
                            height: 42
                            radius: theme.radiusControl
                            color: theme.darkMode ? Qt.rgba(1,1,1,0.03) : Qt.rgba(0,0,0,0.02)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                Label {
                                    text: modelData.key
                                    color: theme.textSecondary
                                    font.family: theme.fontText
                                    font.pixelSize: theme.sizeBody
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: modelData.val
                                    color: theme.textPrimary
                                    font.family: theme.fontText
                                    font.pixelSize: theme.sizeBody
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: theme.space8 }

                // Navigation
                RowLayout {
                    width: parent.width
                    spacing: theme.space12

                    FlowButton {
                        label: "Back"
                        variant: "secondary"
                        onClicked: root.step = 1
                    }

                    Item { Layout.fillWidth: true }

                    FlowButton {
                        label: "Start Dictating"
                        variant: "primary"
                        accent: theme.primary
                        onClicked: {
                            AppController.completeOnboarding(
                                root.providerDraft,
                                root.apiKeyDraft,
                                root.modelDraft,
                                root.languageDraft,
                                true
                            )
                        }
                    }
                }
            }
        }
    }
}
