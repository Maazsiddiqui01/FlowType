import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: root

    property var selectedCard: null
    property string placeholderText: "Select a model"
    property string emptyText: "No models available yet"

    signal optionPicked(int index)

    implicitHeight: 50
    leftPadding: 12
    rightPadding: 40

    onActivated: optionPicked(currentIndex)

    background: Rectangle {
        radius: 16
        color: "#ffffff"
        border.width: 1
        border.color: root.visualFocus ? "#89b4ff" : "#dce7ed"
    }

    indicator: Canvas {
        x: root.width - width - 14
        y: (root.height - height) / 2
        width: 12
        height: 8
        contextType: "2d"

        onPaint: {
            context.reset()
            context.lineWidth = 1.6
            context.lineCap = "round"
            context.lineJoin = "round"
            context.strokeStyle = "#7a8e9d"
            context.beginPath()
            context.moveTo(1, 1)
            context.lineTo(width / 2, height - 1)
            context.lineTo(width - 1, 1)
            context.stroke()
        }
    }

    contentItem: RowLayout {
        spacing: 10

        ProviderBadge {
            visible: root.selectedCard !== null
            compact: true
            badge: root.selectedCard === null ? "" : root.selectedCard.familyBadge
            accent: root.selectedCard === null ? "#2563eb" : root.selectedCard.familyAccent
            badgeBackground: root.selectedCard === null ? "#edf3f7" : root.selectedCard.familyBadgeBackground
            badgeForeground: root.selectedCard === null ? "#173042" : root.selectedCard.familyBadgeForeground
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Label {
                Layout.fillWidth: true
                text: root.selectedCard === null ? root.placeholderText : root.selectedCard.label
                color: "#173042"
                font.family: "Segoe UI Variable Text"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                visible: root.selectedCard !== null
                text: root.selectedCard === null ? "" : root.selectedCard.tags.join(" / ")
                color: "#60788a"
                font.family: "Segoe UI Variable Text"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    delegate: ItemDelegate {
        width: ListView.view ? ListView.view.width : root.width
        height: 68
        leftPadding: 10
        rightPadding: 10
        highlighted: root.highlightedIndex === index

        background: Rectangle {
            radius: 14
            color: highlighted ? "#eef5ff" : (hovered ? "#f7fbfe" : "#ffffff")
            border.width: 1
            border.color: highlighted ? "#bdd4ff" : "#ffffff"
        }

        contentItem: RowLayout {
            spacing: 10

            ProviderBadge {
                compact: true
                badge: modelData.familyBadge
                accent: modelData.familyAccent
                badgeBackground: modelData.familyBadgeBackground
                badgeForeground: modelData.familyBadgeForeground
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: "#163042"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 4

                        Repeater {
                            model: modelData.tags

                            delegate: Rectangle {
                                radius: 10
                                color: modelData === "Free"
                                    ? "#e9fbf1"
                                    : (modelData === "Paid"
                                        ? "#eff4ff"
                                        : "#f4f7fa")
                                border.width: 1
                                border.color: modelData === "Free"
                                    ? "#bfe9cf"
                                    : (modelData === "Paid"
                                        ? "#cfe0ff"
                                        : "#dde8ef")
                                implicitWidth: tagLabel.implicitWidth + 12
                                implicitHeight: 22

                                Label {
                                    id: tagLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: modelData === "Free"
                                        ? "#1f7a4d"
                                        : (modelData === "Paid"
                                            ? "#315dbe"
                                            : "#557186")
                                    font.family: "Segoe UI Variable Text"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: modelData.speed + " / " + modelData.quality + " / " + modelData.cost
                    color: "#597386"
                    font.family: "Segoe UI Variable Text"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }

    popup: Popup {
        y: root.height + 6
        width: root.width
        padding: 8
        implicitHeight: Math.min(contentItem.implicitHeight + (padding * 2), 360)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            radius: 18
            color: "#ffffff"
            border.width: 1
            border.color: "#dce7ed"
        }

        contentItem: Loader {
            active: root.popup.visible
            sourceComponent: (root.model && root.model.length > 0) ? populatedModelComponent : emptyModelComponent
        }
    }

    Component {
        id: populatedModelComponent

        ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            spacing: 6
            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }

    Component {
        id: emptyModelComponent

        Rectangle {
            implicitHeight: 72
            color: "transparent"

            Label {
                anchors.centerIn: parent
                text: root.emptyText
                color: "#72879a"
                font.family: "Segoe UI Variable Text"
                font.pixelSize: 12
            }
        }
    }
}
