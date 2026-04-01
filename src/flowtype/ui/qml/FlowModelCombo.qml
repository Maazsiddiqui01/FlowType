import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: root

    Theme { id: theme }

    property var modelCards: []

    model: {
        var items = []
        for (var i = 0; i < root.modelCards.length; i += 1)
            items.push(root.modelCards[i].label)
        return items
    }

    width: 280
    height: theme.controlHeight

    delegate: ItemDelegate {
        width: ListView.view ? ListView.view.width : root.width
        height: 38

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: theme.space8

            ProviderBadge {
                providerId: root.modelCards[index] ? root.modelCards[index].providerId || "" : ""
                badgeText: root.modelCards[index] ? root.modelCards[index].badge || "" : ""
                accentColor: theme.textSecondary
                width: 24
                height: 24
                visible: root.modelCards[index] ? ((root.modelCards[index].badge || "").length > 0 || (root.modelCards[index].providerId || "").length > 0) : false
            }

            Label {
                Layout.fillWidth: true
                text: modelData
                color: root.highlightedIndex === index ? theme.textPrimary : theme.textPrimary
                font.family: theme.fontUi
                font.pixelSize: theme.sizeBody
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            color: root.highlightedIndex === index ? theme.surfaceHover : "transparent"
            radius: theme.radiusControl
        }
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 34
        spacing: theme.space8

        ProviderBadge {
            providerId: root.currentIndex >= 0 && root.currentIndex < root.modelCards.length ? root.modelCards[root.currentIndex].providerId || "" : ""
            badgeText: root.currentIndex >= 0 && root.currentIndex < root.modelCards.length ? root.modelCards[root.currentIndex].badge || "" : ""
            accentColor: theme.textSecondary
            width: 24
            height: 24
            visible: root.currentIndex >= 0 && root.currentIndex < root.modelCards.length
                ? ((root.modelCards[root.currentIndex].badge || "").length > 0 || (root.modelCards[root.currentIndex].providerId || "").length > 0)
                : false
        }

        Label {
            Layout.fillWidth: true
            text: root.displayText
            color: theme.textPrimary
            font.family: theme.fontUi
            font.pixelSize: theme.sizeBody
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    indicator: Label {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: popup.visible ? "\u25B4" : "\u25BE"
        color: theme.textSecondary
        font.pixelSize: 12
    }

    background: Rectangle {
        radius: theme.radiusControl
        color: hoverArea.containsMouse ? theme.surfaceHover : theme.surface
        border.width: root.popup.visible ? 1 : 1
        border.color: root.popup.visible ? theme.borderSelected : theme.border
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        padding: 6

        contentItem: ListView {
            implicitHeight: Math.min(contentHeight, 280)
            clip: true
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }

        background: Rectangle {
            radius: theme.radiusControl
            color: theme.surface
            border.width: 1
            border.color: theme.border
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }
}
