import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string hudStyleDraft: AppController.hudStyle
    property string hudPositionDraft: AppController.hudPosition
    property bool showIdleHudDraft: AppController.showIdleHud
    property string minDurationDraft: String(AppController.minDurationMs)
    property string maxDurationDraft: String(AppController.maxDurationSeconds)
    property string pasteDelayDraft: String(AppController.pasteDelayMs)

    function asInt(text, fallback) {
        var value = parseInt(text)
        return isNaN(value) ? fallback : value
    }

    function previewWaveMode() {
        if (AppController.status === "recording") return "recording"
        if (AppController.status === "error") return "error"
        if (AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting") return "busy"
        return "recording"
    }

    Connections {
        target: AppController
        function onConfigChanged() {
            root.hudStyleDraft = AppController.hudStyle
            root.hudPositionDraft = AppController.hudPosition
            root.showIdleHudDraft = AppController.showIdleHud
            root.minDurationDraft = String(AppController.minDurationMs)
            root.maxDurationDraft = String(AppController.maxDurationSeconds)
            root.pasteDelayDraft = String(AppController.pasteDelayMs)
        }
    }

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
                text: "Recording Experience"
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizePageTitle
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── HUD Presentation ─────────────────────────────
        RowLayout {
            width: parent.width
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignTop

                Column {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "HUD Preview"
                        subtitle: "See how the recording indicator will look when you dictate. Changes apply immediately."
                    }

                    Rectangle {
                        width: parent.width
                        height: 140
                        radius: theme.radiusControl
                        color: theme.surfaceSubtle
                        border.width: 1
                        border.color: theme.border

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.hudStyleDraft === "mini" ? 136 : 176
                            height: root.hudStyleDraft === "mini" ? 40 : 48
                            radius: height / 2
                            color: theme.darkMode ? "#0A0E16" : "#0C1622"
                            border.width: 1
                            border.color: theme.darkMode ? "#1A2538" : "#243446"

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    visible: root.showIdleHudDraft || AppController.status !== "ready"
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: theme.darkMode ? "#0C1622" : "#0A0E16"
                                    border.width: 1
                                    border.color: theme.darkMode ? "#1E3048" : "#233447"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Label {
                                        anchors.centerIn: parent
                                        text: AppController.transcriptionLanguage === "auto"
                                            ? "A"
                                            : AppController.transcriptionLanguage.toUpperCase().slice(0, 2)
                                        color: "#F0F4F8"
                                        font.family: theme.fontUi
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                }

                                WaveStrip {
                                    anchors.verticalCenter: parent.verticalCenter
                                    bars: root.hudStyleDraft === "mini" ? 7 : 9
                                    barWidth: 4
                                    gap: 4
                                    minimumBarHeight: 3
                                    maximumBarHeight: root.hudStyleDraft === "mini" ? 14 : 20
                                    level: Math.max(AppController.audioLevel, 0.34)
                                    mode: root.previewWaveMode()
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignTop

                Column {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "HUD Appearance"
                        subtitle: "Control the style and positioning of the floating dictation indicator."
                    }

                    Column {
                        width: parent.width
                        spacing: theme.space12

                        Row {
                            spacing: theme.space8

                            ChoiceCard {
                                width: 140
                                compact: true
                                hideChevron: true
                                title: "Mini"
                                subtitle: "Compact pill"
                                selected: root.hudStyleDraft === "mini"
                                onClicked: {
                                    root.hudStyleDraft = "mini"
                                    AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                                }
                            }

                            ChoiceCard {
                                width: 140
                                compact: true
                                hideChevron: true
                                title: "Classic"
                                subtitle: "Wider pill"
                                selected: root.hudStyleDraft === "classic"
                                onClicked: {
                                    root.hudStyleDraft = "classic"
                                    AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                                }
                            }
                        }

                        Row {
                            spacing: theme.space8

                            ChoiceCard {
                                width: 140
                                compact: true
                                hideChevron: true
                                title: "Bottom"
                                subtitle: "Bottom-center"
                                selected: root.hudPositionDraft === "bottom"
                                onClicked: {
                                    root.hudPositionDraft = "bottom"
                                    AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                                }
                            }

                            ChoiceCard {
                                width: 140
                                compact: true
                                hideChevron: true
                                title: "Top"
                                subtitle: "Top-center"
                                selected: root.hudPositionDraft === "top"
                                onClicked: {
                                    root.hudPositionDraft = "top"
                                    AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                                }
                            }
                        }

                        FormRow {
                            width: parent.width
                            title: "Show subtle line while idle"
                            subtitle: "Keep a minimal indicator visible when FlowType is waiting."

                            FlowSwitch {
                                checked: root.showIdleHudDraft
                                onClicked: {
                                    root.showIdleHudDraft = checked
                                    AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Recording Timing ─────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Recording Timing"
                    subtitle: "Fine-tune latency and bounds for audio capture."

                    trailing: FlowButton {
                        label: "Save Timing"
                        variant: "primary"
                        accent: theme.primary
                        onClicked: AppController.saveExperienceSettings(
                            root.hudStyleDraft,
                            root.hudPositionDraft,
                            root.showIdleHudDraft,
                            root.asInt(root.minDurationDraft, AppController.minDurationMs),
                            root.asInt(root.maxDurationDraft, AppController.maxDurationSeconds),
                            root.asInt(root.pasteDelayDraft, AppController.pasteDelayMs)
                        )
                    }
                }

                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: theme.space12
                    rowSpacing: theme.space12

                    Repeater {
                        model: [
                            { "label": "Minimum tap length (ms)", "kind": "min", "placeholder": "250" },
                            { "label": "Safety limit (seconds)", "kind": "max", "placeholder": "300" },
                            { "label": "Paste delay (ms)", "kind": "paste", "placeholder": "80" }
                        ]

                        delegate: InputSurface {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            height: 64

                            Column {
                                width: parent.width
                                spacing: 4

                                Label {
                                    text: modelData.label
                                    color: theme.textSecondary
                                    font.family: theme.fontUi
                                    font.pixelSize: theme.sizeLabel
                                }

                                TextField {
                                    width: parent.width
                                    text: modelData.kind === "min" ? root.minDurationDraft : (modelData.kind === "max" ? root.maxDurationDraft : root.pasteDelayDraft)
                                    color: theme.textPrimary
                                    font.family: theme.fontText
                                    font.pixelSize: theme.sizeBody
                                    font.weight: Font.DemiBold
                                    validator: IntValidator { bottom: 0 }
                                    background: null
                                    placeholderText: modelData.placeholder
                                    onTextChanged: {
                                        if (modelData.kind === "min") root.minDurationDraft = text
                                        else if (modelData.kind === "max") root.maxDurationDraft = text
                                        else root.pasteDelayDraft = text
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
