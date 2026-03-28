import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property int currentSection: 0

    readonly property var sections: [
        { "title": "General", "subtitle": "Shortcuts and local behavior" },
        { "title": "Cleanup", "subtitle": "Providers, models, and paste behavior" },
        { "title": "Recording", "subtitle": "HUD presentation and timing" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: theme.sectionGap

        SectionCard {
            Layout.fillWidth: true
            padding: theme.cardPadding

            RowLayout {
                width: parent.width
                spacing: theme.space24

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Settings that actually affect daily dictation"
                        color: theme.textPrimary
                        font.family: theme.fontDisplay
                        font.pixelSize: theme.sizeSectionTitle + 8
                        font.weight: Font.Black
                    }

                    Label {
                        text: "Keep the setup lean: shortcuts, cleanup provider, model selection, paste behavior, and recording feel."
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textBody
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                StatusPill {
                    statusText: AppController.status === "ready" ? "Ready" : AppController.status.toUpperCase()
                    tone: AppController.status === "error"
                        ? theme.error
                        : (AppController.status === "recording"
                            ? theme.warm
                            : (AppController.status === "ready" ? theme.success : theme.primary))
                }
            }
        }

        Row {
            Layout.fillWidth: true
            spacing: theme.space8

            Repeater {
                model: root.sections

                delegate: Rectangle {
                    radius: theme.radiusControl
                    color: root.currentSection === index ? theme.tint(theme.primary, 0.08) : theme.surface
                    border.width: 1
                    border.color: root.currentSection === index ? theme.tint(theme.primary, 0.28) : theme.border
                    implicitWidth: tabLabel.implicitWidth + 26
                    implicitHeight: theme.controlHeightCompact

                    Label {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: modelData.title
                        color: root.currentSection === index ? theme.textPrimary : theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.textBody
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
                id: settingsStack
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
