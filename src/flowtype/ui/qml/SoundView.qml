import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

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
        maxContentWidth: 1160
        contentSpacing: 18

        SurfacePanel {
            width: parent.width
            prominent: true
            accent: "#f97316"
            cornerRadius: 28
            padding: 24
            borderTone: "#dfe8ef"

            RowLayout {
                width: parent.width
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Recording HUD and timing"
                        color: "#163042"
                        font.family: "Segoe UI Variable Display"
                        font.pixelSize: 28
                        font.weight: Font.Black
                    }

                    Label {
                        text: "Mini keeps the overlay subtle. Classic gives a slightly fuller pill. Both stay tiny while idle and only expand when needed."
                        color: "#627b8e"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                FlowButton {
                    label: "Save Recording"
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
        }

        Flow {
            width: parent.width
            spacing: 14

            Repeater {
                model: [
                    { "id": "mini", "label": "Mini", "detail": "Smallest desktop footprint, closest to the Wispr-style bar." },
                    { "id": "classic", "label": "Classic", "detail": "Slightly larger pill with more breathing room." }
                ]

                delegate: Rectangle {
                    width: 316
                    height: 176
                    radius: 22
                    color: root.hudStyleDraft === modelData.id ? Qt.rgba(249 / 255, 115 / 255, 22 / 255, 0.12) : "#ffffff"
                    border.width: 1
                    border.color: root.hudStyleDraft === modelData.id ? "#f5b27a" : "#dce7ed"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 14

                        Rectangle {
                            width: modelData.id === "mini" ? 96 : 132
                            height: modelData.id === "mini" ? 34 : 42
                            radius: height / 2
                            color: "#070b0f"
                            border.width: 1
                            border.color: "#26384a"

                            WaveStrip {
                                anchors.centerIn: parent
                                bars: modelData.id === "mini" ? 7 : 10
                                barWidth: modelData.id === "mini" ? 3 : 4
                                gap: 3
                                minimumBarHeight: 3
                                maximumBarHeight: modelData.id === "mini" ? 12 : 16
                                level: 0.46
                                mode: "recording"
                            }
                        }

                        Label {
                            text: modelData.label
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 22
                            font.weight: Font.Black
                        }

                        Label {
                            width: parent.width
                            text: modelData.detail
                            color: "#627b8e"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.hudStyleDraft = modelData.id
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
                spacing: 14

                RowLayout {
                    width: parent.width

                    Label {
                        text: "Show subtle ready line while idle"
                        color: "#173042"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }

                    FlowSwitch {
                        checked: root.showIdleHudDraft
                        onToggled: root.showIdleHudDraft = checked
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: [
                            { "label": "Minimum tap length (ms)", "kind": "min" },
                            { "label": "Safety limit (seconds)", "kind": "max" },
                            { "label": "Paste delay (ms)", "kind": "paste" }
                        ]

                        delegate: Rectangle {
                            width: 280
                            height: 96
                            radius: 20
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#dce7ed"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                Label {
                                    text: modelData.label
                                    color: "#6a8496"
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 12
                                }

                                TextField {
                                    text: modelData.kind === "min" ? root.minDurationDraft : (modelData.kind === "max" ? root.maxDurationDraft : root.pasteDelayDraft)
                                    color: "#173042"
                                    font.family: "Bahnschrift SemiBold"
                                    font.pixelSize: 20
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

                RowLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: "HUD position"
                        color: "#173042"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                    }

                    Rectangle {
                        radius: 16
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#dce7ed"
                        implicitWidth: positionRow.implicitWidth + 12
                        implicitHeight: 38

                        Row {
                            id: positionRow
                            anchors.centerIn: parent
                            spacing: 6

                            Repeater {
                                model: [
                                    { "id": "bottom", "label": "Bottom" },
                                    { "id": "top", "label": "Top" }
                                ]

                                delegate: Rectangle {
                                    radius: 13
                                    color: root.hudPositionDraft === modelData.id ? "#eef5ff" : "transparent"
                                    border.width: root.hudPositionDraft === modelData.id ? 1 : 0
                                    border.color: "#bdd4ff"
                                    implicitWidth: posLabel.implicitWidth + 16
                                    implicitHeight: 28

                                    Label {
                                        id: posLabel
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: "#173042"
                                        font.family: "Segoe UI Variable Text"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.hudPositionDraft = modelData.id
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
