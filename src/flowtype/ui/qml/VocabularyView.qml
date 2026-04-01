import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string textDraft: AppController.vocabularyText

    Connections {
        target: AppController
        function onConfigChanged() {
            root.textDraft = AppController.vocabularyText
        }
    }

    PageScroll {
        anchors.fill: parent
        maxContentWidth: 900
        contentSpacing: theme.space24

        // ── Header Actions ───────────────────────────────
        Item {
            width: parent.width
            height: headLabel.implicitHeight

            Label {
                id: headLabel
                text: "Vocabulary"
                color: theme.textPrimary
                font.family: theme.fontDisplay
                font.pixelSize: theme.sizePageTitle
                font.weight: Font.Bold
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            FlowButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                label: "Save Vocabulary"
                variant: "primary"
                accent: theme.primary
                onClicked: AppController.saveVocabulary(root.textDraft)
            }
        }

        // ── Vocabulary Input ─────────────────────────────
        SectionCard {
            width: parent.width

            Column {
                width: parent.width
                spacing: theme.space16

                SectionHeader {
                    title: "Custom Words & Phrases"
                    subtitle: "Teach FlowType specific spellings, names, punctuation macros, or product jargon. Enter one per line."
                }

                Rectangle {
                    width: parent.width
                    height: 380
                    radius: theme.radiusControl
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.border

                    TextArea {
                        anchors.fill: parent
                        anchors.margins: 16
                        text: root.textDraft
                        color: theme.textPrimary
                        wrapMode: TextEdit.Wrap
                        font.family: theme.fontMono
                        font.pixelSize: theme.sizeBody
                        background: null
                        placeholderText: "Example entries:\nFlowType (not flow type)\nLaTeX\nCEO\njohn.doe@example.com"
                        placeholderTextColor: theme.textTertiary
                        onTextChanged: root.textDraft = text
                    }
                }
            }
        }
    }
}
