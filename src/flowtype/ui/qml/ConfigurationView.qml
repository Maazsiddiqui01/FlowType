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

    function selectedProviderLabel() {
        var cards = AppController.providerCards
        for (var i = 0; i < cards.length; i += 1) {
            if (cards[i].identifier === root.providerDraft)
                return cards[i].label
        }
        return "provider"
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
        maxContentWidth: 1180
        contentSpacing: theme.sectionGap

        SectionCard {
            width: parent.width

            ColumnLayout {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Cleanup provider"
                    subtitle: "Choose the provider that polishes your local transcript. Keep the selection lean and predictable."

                    trailing: FlowButton {
                        label: "Save Changes"
                        variant: "primary"
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
                    width: parent.width
                    columns: width > 920 ? 3 : 2
                    columnSpacing: theme.space12
                    rowSpacing: theme.space12

                    Repeater {
                        model: AppController.providerCards

                        delegate: ChoiceCard {
                            Layout.fillWidth: true
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

        RowLayout {
            width: parent.width
            spacing: theme.space12

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: root.providerNeedsKey ? "API key" : "Connection"
                        subtitle: root.providerDraft === "ollama"
                            ? "Ollama uses the default localhost endpoint."
                            : (root.providerNeedsKey
                                ? "Paste your private API key. FlowType never proxies your requests."
                                : "Local-only cleanup does not need a key.")
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: theme.radiusControl
                        color: theme.surfaceSubtle
                        border.width: 1
                        border.color: theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: theme.space12
                            anchors.rightMargin: theme.space12
                            spacing: theme.space8

                            TextField {
                                Layout.fillWidth: true
                                text: root.apiKeyDraft
                                color: theme.textPrimary
                                echoMode: root.showApiKey ? TextInput.Normal : TextInput.Password
                                placeholderText: root.providerNeedsKey ? "Paste your API key" : "Not required"
                                placeholderTextColor: theme.textTertiary
                                readOnly: !root.providerNeedsKey
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeBody
                                background: null
                                onTextChanged: root.apiKeyDraft = text
                            }

                            FlowButton {
                                visible: root.providerNeedsKey
                                label: root.showApiKey ? "Hide" : "Show"
                                variant: "secondary"
                                onClicked: root.showApiKey = !root.showApiKey
                            }
                        }
                    }

                    Label {
                        visible: root.providerNeedsKey
                        text: "Get your " + root.selectedProviderLabel() + " key"
                        color: theme.primary
                        font.family: theme.fontUi
                        font.pixelSize: theme.sizeHelper
                        font.weight: 650

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AppController.openProviderKeyPage(root.providerDraft)
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
                        title: "Cleanup model"
                        subtitle: "Choose the specific model version used for cleanup."
                    }

                    FlowModelCombo {
                        Layout.fillWidth: true
                        width: parent.width
                        modelCards: root.providerModels
                        currentIndex: root.modelIndex()
                        onActivated: function(index) { root.modelDraft = root.providerModels[index].identifier }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: theme.radiusControl
                        color: theme.surfaceSubtle
                        border.width: 1
                        border.color: theme.border
                        visible: root.providerDraft !== "none" && root.providerModels.length === 0

                        TextField {
                            anchors.fill: parent
                            anchors.leftMargin: theme.space12
                            anchors.rightMargin: theme.space12
                            text: root.modelDraft
                            color: theme.textPrimary
                            placeholderText: "Enter an exact model ID"
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

        RowLayout {
            width: parent.width
            spacing: theme.space12

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1.6

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Base cleanup prompt"
                        subtitle: "Use this for the global cleanup behavior. Keep it short and stable."
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
                            text: root.promptDraft
                            color: theme.textPrimary
                            wrapMode: TextEdit.Wrap
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeBody
                            background: null
                            onTextChanged: root.promptDraft = text
                        }
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 320
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Output behavior"
                        subtitle: "Decide what FlowType does after cleanup finishes."
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: theme.space12

                        ChoiceCard {
                            Layout.fillWidth: true
                            compact: true
                            hideChevron: true
                            title: "Paste into active app"
                            subtitle: "Copy and paste immediately"
                            selected: root.pasteMethodDraft === "ctrl_v"
                            accent: theme.primary
                            onClicked: root.pasteMethodDraft = "ctrl_v"
                        }

                        ChoiceCard {
                            Layout.fillWidth: true
                            compact: true
                            hideChevron: true
                            title: "Clipboard only"
                            subtitle: "Copy and let you paste manually"
                            selected: root.pasteMethodDraft === "clipboard_only"
                            accent: theme.primary
                            onClicked: root.pasteMethodDraft = "clipboard_only"
                        }

                        FormRow {
                            width: parent.width
                            title: "Restore prior clipboard"
                            subtitle: "Put the previous clipboard contents back after auto-paste."

                            FlowSwitch {
                                checked: root.restoreClipboardDraft
                                onClicked: root.restoreClipboardDraft = checked
                            }
                        }
                    }
                }
            }
        }
    }
}
