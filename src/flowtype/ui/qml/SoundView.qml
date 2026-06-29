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
        maxContentWidth: 1180
        contentSpacing: theme.sectionGap

        RowLayout {
            width: parent.width
            spacing: theme.space12

            SectionCard {
                Layout.preferredWidth: 420
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                SectionHeader {
                    title: "Recording HUD"
                    subtitle: "The floating indicator stays hidden until dictation starts unless you explicitly keep the idle line visible."
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        radius: theme.radiusCard
                        color: theme.surfaceSubtle
                        border.width: 1
                        border.color: theme.border

                        Column {
                            anchors.centerIn: parent
                            spacing: 18

                            // Idle: the minimal blank line (when enabled).
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: root.showIdleHudDraft
                                width: 40
                                height: 4
                                radius: 2
                                color: theme.darkMode ? "#33405A" : "#9AA8BC"
                            }

                            // Recording: the compact pill (state dot + waveform + label).
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: pillRow.implicitWidth + 28
                                height: root.hudStyleDraft === "mini" ? 38 : 44
                                radius: height / 2
                                color: theme.darkMode ? "#0A0E16" : "#0B1622"
                                border.width: 1
                                border.color: theme.darkMode ? "#1D2737" : "#243446"

                                Row {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 9

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: theme.warm
                                    }

                                    WaveStrip {
                                        anchors.verticalCenter: parent.verticalCenter
                                        bars: root.hudStyleDraft === "mini" ? 7 : 9
                                        barWidth: 4
                                        gap: 4
                                        minimumBarHeight: 3
                                        maximumBarHeight: root.hudStyleDraft === "mini" ? 14 : 18
                                        level: Math.max(AppController.audioLevel, 0.25)
                                        mode: root.previewWaveMode()
                                    }

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Recording"
                                        color: "#EEF4FA"
                                        font.family: theme.fontUi
                                        font.pixelSize: theme.sizeHelper
                                        font.weight: 700
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "The idle line expands to a 'Dictate' hint on hover, becomes the recording pill while you speak, and hides over fullscreen video and games. Style and position apply immediately."
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeHelper
                        wrapMode: Text.WordWrap
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                SectionHeader {
                    title: "Appearance"
                    subtitle: "Keep the HUD compact, centered, and easy to trust while you are speaking."
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: theme.space12

                        ChoiceCard {
                            Layout.fillWidth: true
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
                            Layout.fillWidth: true
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: theme.space12

                        ChoiceCard {
                            Layout.fillWidth: true
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
                            Layout.fillWidth: true
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
                        title: "Show idle line"
                        subtitle: "Keep a minimal waiting indicator visible even when FlowType is not recording."

                        FlowSwitch {
                            checked: root.showIdleHudDraft
                            onToggled: function(value) {
                                root.showIdleHudDraft = value
                                AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
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
                    title: "Capture timing"
                    subtitle: "Fine-tune capture bounds and paste delay without changing the transcription pipeline."

                    trailing: FlowButton {
                        label: "Save Timing"
                        variant: "primary"
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

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 78
                            radius: theme.radiusCard
                            color: theme.surfaceSubtle
                            border.width: 1
                            border.color: theme.border

                            Column {
                                anchors.fill: parent
                                anchors.margins: theme.space12
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
                                    font.family: theme.fontUi
                                    font.pixelSize: theme.sizeBody
                                    font.weight: 650
                                    validator: IntValidator { bottom: 0 }
                                    background: null
                                    placeholderText: modelData.placeholder
                                    placeholderTextColor: theme.textTertiary
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
