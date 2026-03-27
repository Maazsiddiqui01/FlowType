import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int currentSection: 0

    readonly property var sections: [
        { "title": "General", "subtitle": "Shortcuts and language", "accent": "#0d9488" },
        { "title": "Cleanup", "subtitle": "Providers, models, and paste behavior", "accent": "#2563eb" },
        { "title": "Recording", "subtitle": "HUD and timing", "accent": "#f97316" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        SurfacePanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 116
            prominent: true
            accent: root.sections[root.currentSection].accent
            cornerRadius: 26
            padding: 20

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Settings that actually affect daily dictation"
                            color: "#163042"
                            font.family: "Segoe UI Variable Display"
                            font.pixelSize: 28
                            font.weight: Font.Black
                        }

                        Label {
                            text: "Keep the setup lean: shortcuts, cleanup provider, model selection, paste behavior, and recording feel."
                            color: "#6b8496"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        radius: 16
                        color: "#ffffff"
                        border.width: 1
                        border.color: "#d9e6ed"
                        implicitWidth: statusRow.implicitWidth + 22
                        implicitHeight: 34

                        RowLayout {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: AppController.status === "ready" ? "#0d9488" : "#2563eb"
                            }

                            Label {
                                text: AppController.status === "ready" ? "Ready" : AppController.status.toUpperCase()
                                color: "#173042"
                                font.family: "Bahnschrift SemiBold"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Row {
                    spacing: 10

                    Repeater {
                        model: root.sections

                        delegate: Rectangle {
                            radius: 16
                            color: root.currentSection === index ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.12) : "#ffffff"
                            border.width: 1
                            border.color: root.currentSection === index ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.38) : "#dbe7ee"
                            implicitWidth: tabLabel.implicitWidth + 28
                            implicitHeight: 38

                            Label {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.title
                                color: root.currentSection === index ? "#173042" : "#456174"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentSection = index
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentSection

                GeneralSettingsView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                ConfigurationView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SoundView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
