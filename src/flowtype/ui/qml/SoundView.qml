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
        if (AppController.status === "recording")
            return "recording"
        if (AppController.status === "error")
            return "error"
        if (AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting")
            return "busy"
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
        maxContentWidth: 1240
        contentSpacing: theme.sectionGap

        RowLayout {
            width: parent.width
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 230

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Recording HUD"
                    subtitle: "Style, position, and idle visibility apply immediately."
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 90
                    spacing: theme.space12

                    Rectangle {
                        width: root.hudStyleDraft === "mini" ? 124 : 164
                        height: root.hudStyleDraft === "mini" ? 36 : 44
                        radius: height / 2
                        color: theme.inkDark
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                visible: root.showIdleHudDraft || AppController.status !== "ready"
                                width: 20
                                height: 20
                                radius: 10
                                color: "#0C1622"
                                border.width: 1
                                border.color: "#233447"

                                Label {
                                    anchors.centerIn: parent
                                    text: AppController.transcriptionLanguage === "auto"
                                        ? "A"
                                        : AppController.transcriptionLanguage.toUpperCase().slice(0, 2)
                                    color: "#F7FAFC"
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
                                minimumBarHeight: 4
                                maximumBarHeight: root.hudStyleDraft === "mini" ? 14 : 18
                                level: Math.max(AppController.audioLevel, 0.34)
                                mode: root.previewWaveMode()
                            }
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.hudPositionDraft === "top"
                            ? "Previewing top-center placement"
                            : "Previewing bottom-center placement"
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textHelper
                    }
                }
            }

            SectionCard {
                Layout.preferredWidth: 360
                Layout.preferredHeight: 230

                SectionHeader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    title: "Presentation"
                    subtitle: "Keep the HUD small, centered, and easy to trust."
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 76
                    spacing: theme.space12

                    Row {
                        spacing: theme.space8

                        ChoiceCard {
                            width: 140
                            compact: true
                            hideChevron: true
                            title: "Mini"
                            selected: root.hudStyleDraft === "mini"
                            accent: theme.warm
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
                            selected: root.hudStyleDraft === "classic"
                            accent: theme.warm
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
                            title: "Bottom center"
                            selected: root.hudPositionDraft === "bottom"
                            accent: theme.primary
                            onClicked: {
                                root.hudPositionDraft = "bottom"
                                AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                            }
                        }

                        ChoiceCard {
                            width: 140
                            compact: true
                            hideChevron: true
                            title: "Top center"
                            selected: root.hudPositionDraft === "top"
                            accent: theme.primary
                            onClicked: {
                                root.hudPositionDraft = "top"
                                AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                            }
                        }
                    }

                    FormRow {
                        width: parent.width
                        title: "Show subtle ready line while idle"
                        detail: "Keep a minimal ready indicator visible when FlowType is waiting."

                        FlowSwitch {
                            checked: root.showIdleHudDraft
                            onToggled: {
                                root.showIdleHudDraft = checked
                                AppController.saveHudPresentation(root.hudStyleDraft, root.hudPositionDraft, root.showIdleHudDraft)
                            }
                        }
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
                title: "Recording timing"
                subtitle: "Timing values require a save. Presentation changes above apply instantly."

                trailing: FlowButton {
                    label: "Save Timing"
                    variant: "warm"
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
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 74
                columns: 3
                columnSpacing: theme.space12
                rowSpacing: theme.space12

                Repeater {
                    model: [
                        { "label": "Minimum tap length (ms)", "kind": "min" },
                        { "label": "Safety limit (seconds)", "kind": "max" },
                        { "label": "Paste delay (ms)", "kind": "paste" }
                    ]

                    delegate: SectionCard {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        baseColor: theme.surfaceSubtle

                        Column {
                            width: parent.width
                            spacing: theme.space8

                            Label {
                                text: modelData.label
                                color: theme.textSecondary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textHelper
                            }

                            TextField {
                                width: parent.width
                                text: modelData.kind === "min" ? root.minDurationDraft : (modelData.kind === "max" ? root.maxDurationDraft : root.pasteDelayDraft)
                                color: theme.textPrimary
                                font.family: theme.fontDisplay
                                font.pixelSize: 24
                                font.weight: Font.Black
                                validator: IntValidator { bottom: 0 }
                                background: null
                                onTextChanged: {
                                    if (modelData.kind === "min")
                                        root.minDurationDraft = text
                                    else if (modelData.kind === "max")
                                        root.maxDurationDraft = text
                                    else
                                        root.pasteDelayDraft = text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
