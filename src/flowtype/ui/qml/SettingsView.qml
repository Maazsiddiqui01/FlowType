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
        spacing: 10

        Label {
            text: "Settings that actually affect daily dictation"
            color: "#163042"
            font.family: "Segoe UI Variable Display"
            font.pixelSize: 30
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

        Row {
            spacing: 8

            Repeater {
                model: root.sections

                delegate: Rectangle {
                    radius: 15
                    color: root.currentSection === index ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.11) : "#ffffff"
                    border.width: 1
                    border.color: root.currentSection === index ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.34) : "#dbe7ee"
                    implicitWidth: tabLabel.implicitWidth + 26
                    implicitHeight: 34

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
