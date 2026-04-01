import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string textDraft: AppController.vocabularyText

    function vocabularyEntries() {
        var lines = root.textDraft.split(/\r?\n/)
        var items = []
        for (var i = 0; i < lines.length; i += 1) {
            var value = lines[i].trim()
            if (value.length > 0)
                items.push(value)
        }
        return items
    }

    Connections {
        target: AppController

        function onConfigChanged() {
            root.textDraft = AppController.vocabularyText
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
                Layout.fillWidth: true
                Layout.preferredWidth: 1.6

                ColumnLayout {
                    width: parent.width
                    spacing: theme.space16

                    SectionHeader {
                        title: "Protected words and phrases"
                        subtitle: "Enter one item per line. Use this for names, brands, acronyms, punctuation macros, and exact spellings."

                        trailing: FlowButton {
                            label: "Save Vocabulary"
                            variant: "primary"
                            onClicked: AppController.saveVocabulary(root.textDraft)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 420
                        radius: theme.radiusCard
                        color: theme.surfaceSubtle
                        border.width: 1
                        border.color: theme.border

                        TextArea {
                            anchors.fill: parent
                            anchors.margins: theme.space16
                            text: root.textDraft
                            color: theme.textPrimary
                            wrapMode: TextEdit.Wrap
                            font.family: theme.fontMono
                            font.pixelSize: theme.sizeBody
                            background: null
                            placeholderText: "FlowType\nGPT-5.4 mini\nRiyadh\njohn.doe@example.com"
                            placeholderTextColor: theme.textTertiary
                            onTextChanged: root.textDraft = text
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
                        title: "Preview"
                        subtitle: "A quick view of the entries that will be injected into the cleanup prompt."
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: root.vocabularyEntries().length > 0
                        sourceComponent: ColumnLayout {
                            width: parent.width
                            spacing: theme.space8

                            Repeater {
                                model: root.vocabularyEntries().slice(0, 8)

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: theme.radiusControl
                                    color: theme.surfaceSubtle
                                    border.width: 1
                                    border.color: theme.border

                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: theme.space12
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.rightMargin: theme.space12
                                        text: modelData
                                        color: theme.textPrimary
                                        font.family: theme.fontText
                                        font.pixelSize: theme.sizeBody
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Label {
                                visible: root.vocabularyEntries().length > 8
                                text: "+" + (root.vocabularyEntries().length - 8) + " more"
                                color: theme.textSecondary
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeHelper
                            }
                        }
                    }

                    EmptyState {
                        visible: root.vocabularyEntries().length === 0
                        title: "No vocabulary entries yet"
                        message: "Add a few names or product terms and they will show up here."
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: theme.divider
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Best results come from short, exact entries. Use one line per item instead of writing long guidance paragraphs here."
                        color: theme.textSecondary
                        font.family: theme.fontText
                        font.pixelSize: theme.sizeHelper
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
