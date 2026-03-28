import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property var model: []
    property var selectedCard: null
    property int currentIndex: -1
    property string placeholderText: "Select a model"
    property string emptyText: "No models available yet"

    signal optionPicked(int index)

    implicitHeight: theme.buttonHeight

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusControl
        color: theme.surface
        border.width: 1
        border.color: mouseArea.containsMouse || popup.visible ? theme.tint(theme.primary, 0.5) : theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: theme.space12
            anchors.rightMargin: theme.space12
            spacing: theme.space8

            ProviderBadge {
                visible: root.selectedCard !== null
                compact: true
                badge: root.selectedCard === null ? "" : root.selectedCard.familyBadge
                accent: root.selectedCard === null ? theme.primary : root.selectedCard.familyAccent
                badgeBackground: root.selectedCard === null ? theme.surfaceSubtle : root.selectedCard.familyBadgeBackground
                badgeForeground: root.selectedCard === null ? theme.textPrimary : root.selectedCard.familyBadgeForeground
                providerId: root.selectedCard === null ? "" : root.selectedCard.family
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Label {
                    Layout.fillWidth: true
                    text: root.selectedCard === null ? root.placeholderText : root.selectedCard.label
                    color: theme.textPrimary
                    font.family: theme.fontUi
                    font.pixelSize: theme.textBody
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.selectedCard !== null
                    text: root.selectedCard === null ? "" : root.selectedCard.tags.join(" • ")
                    color: theme.textSecondary
                    font.family: theme.fontUi
                    font.pixelSize: theme.textLabel
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
                    context.strokeStyle = theme.textTertiary
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
        width: Math.max(root.width, 440)
        padding: theme.space8
        implicitHeight: Math.min(contentItem.implicitHeight + (padding * 2), 360)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            radius: theme.radiusCard
            color: theme.surface
            border.width: 1
            border.color: theme.border
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
            spacing: theme.space4
            ScrollIndicator.vertical: ScrollIndicator { }

            delegate: Rectangle {
                width: ListView.view ? ListView.view.width : root.width
                height: 60
                radius: theme.radiusControl
                color: root.currentIndex === index ? theme.tint(theme.primary, 0.08) : (delegateMouse.containsMouse ? theme.surfaceSubtle : theme.surface)
                border.width: 1
                border.color: root.currentIndex === index ? theme.tint(theme.primary, 0.34) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: theme.space12
                    anchors.rightMargin: theme.space12
                    spacing: theme.space8

                    ProviderBadge {
                        compact: true
                        badge: modelData.familyBadge
                        accent: modelData.familyAccent
                        badgeBackground: modelData.familyBadgeBackground
                        badgeForeground: modelData.familyBadgeForeground
                        providerId: modelData.family
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: theme.space8

                            Label {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: theme.textPrimary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textBody
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: theme.space4

                                Repeater {
                                    model: modelData.tags

                                    delegate: Rectangle {
                                        radius: 10
                                        color: modelData === "Free"
                                            ? theme.tint(theme.success, 0.12)
                                            : (modelData === "Paid"
                                                ? theme.tint(theme.primary, 0.1)
                                                : theme.surfaceSubtle)
                                        border.width: 1
                                        border.color: modelData === "Free"
                                            ? theme.tint(theme.success, 0.3)
                                            : (modelData === "Paid"
                                                ? theme.tint(theme.primary, 0.25)
                                                : theme.border)
                                        implicitWidth: tagLabel.implicitWidth + 12
                                        implicitHeight: 22

                                        Label {
                                            id: tagLabel
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: modelData === "Free"
                                                ? Qt.darker(theme.success, 1.15)
                                                : (modelData === "Paid"
                                                    ? Qt.darker(theme.primary, 1.1)
                                                    : theme.textSecondary)
                                            font.family: theme.fontUi
                                            font.pixelSize: theme.textLabel
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData.speed + " • " + modelData.quality + " • " + modelData.cost
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textLabel
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
                color: theme.textTertiary
                font.family: theme.fontUi
                font.pixelSize: theme.textBody
            }
        }
    }
}
