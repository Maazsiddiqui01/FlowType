import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var model: []
    property var selectedCard: null
    property int currentIndex: -1
    property string placeholderText: "Select a model"
    property string emptyText: "No models available yet"

    signal optionPicked(int index)

    implicitHeight: 52

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#ffffff"
        border.width: 1
        border.color: mouseArea.containsMouse || popup.visible ? "#9cc4f6" : "#dce7ed"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
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
                    text: root.selectedCard === null ? "" : root.selectedCard.tags.join(" · ")
                    color: "#60788a"
                    font.family: "Segoe UI Variable Text"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Canvas {
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
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (popup.visible)
                    popup.close()
                else
                    popup.open()
            }
        }
    }

    Popup {
        id: popup

        y: root.height + 6
        width: Math.max(root.width, 430)
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
            active: popup.visible
            sourceComponent: root.model.length > 0 ? populatedModelComponent : emptyModelComponent
        }
    }

    Component {
        id: populatedModelComponent

        ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.model
            spacing: 6
            ScrollIndicator.vertical: ScrollIndicator { }

            delegate: Rectangle {
                width: ListView.view ? ListView.view.width : root.width
                height: 64
                radius: 14
                color: root.currentIndex === index ? "#eef5ff" : (delegateMouse.containsMouse ? "#f8fbfe" : "#ffffff")
                border.width: 1
                border.color: root.currentIndex === index ? "#bdd4ff" : "#ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
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
                            text: modelData.speed + " · " + modelData.quality + " · " + modelData.cost
                            color: "#597386"
                            font.family: "Segoe UI Variable Text"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: delegateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.optionPicked(index)
                        popup.close()
                    }
                }
            }
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
