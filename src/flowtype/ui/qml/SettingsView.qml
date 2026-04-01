import QtQuick
import QtQuick.Controls

Item {
    id: root

    Theme { id: theme }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 900
        contentSpacing: theme.space24

        // ── Header ───────────────────────────────────────
        Item {
            width: parent.width
            height: headLabel.implicitHeight

            Label {
                id: headLabel
                text: "Preferences & About"
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizePageTitle
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── App Settings ─────────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space8

                FormRow {
                    title: "Start Onboarding"
                    subtitle: "Re-run the first setup wizard to reconfigure connection details."

                    FlowButton {
                        label: "Relaunch Setup"
                        variant: "secondary"
                        onClicked: AppController.resetOnboarding()
                    }
                }
                
                Rectangle { width: parent.width; height: 1; color: theme.divider }
                
                FormRow {
                    title: "Reset Configuration"
                    subtitle: "Return to default values. Backup your data first."

                    FlowButton {
                        label: "Restore Defaults"
                        variant: "secondary"
                        onClicked: AppController.resetConfig()
                    }
                }
            }
        }

        // ── About ────────────────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "About FlowType"
                    subtitle: "Open source, fast, localized voice intelligence."
                }

                Row {
                    spacing: theme.space12

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 8
                        color: theme.primary

                        Label {
                            anchors.centerIn: parent
                            text: "F"
                            color: "#ffffff"
                            font.family: theme.fontDisplay
                            font.pixelSize: 24
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            text: "FlowType v1.0.0-beta"
                            color: theme.textPrimary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeSectionTitle
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: "Built with Faster-Whisper and PySide6."
                            color: theme.textSecondary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeHelper
                        }
                    }
                }
                
                Item { width: 1; height: theme.space8 }
                
                Row {
                    spacing: theme.space8
                    
                    FlowButton {
                        label: "View GitHub Source"
                        variant: "secondary"
                    }
                    
                    FlowButton {
                        label: "Report Issue"
                        variant: "secondary"
                    }
                }
            }
        }
    }
}
