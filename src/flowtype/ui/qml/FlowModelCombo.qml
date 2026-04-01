import QtQuick
import QtQuick.Controls

ComboBox {
    id: root

    Theme { id: theme }

    property var modelCards: []
    
    // Convert cards to strings for the native ComboBox model
    model: {
        var a = []
        for (var i = 0; i < modelCards.length; i++) {
            a.push(modelCards[i].label)
        }
        return a
    }

    // Helper to get selected ID
    function selectedIdentifier() {
        if (root.currentIndex >= 0 && root.currentIndex < modelCards.length) {
            return modelCards[root.currentIndex].identifier
        }
        return ""
    }

    // Helper to set by ID
    function selectByIdentifier(identifier) {
        for (var i = 0; i < modelCards.length; i++) {
            if (modelCards[i].identifier === identifier) {
                root.currentIndex = i
                return
            }
        }
        root.currentIndex = -1
    }

    width: 240
    height: theme.controlHeightCompact
    
    delegate: ItemDelegate {
        width: root.width
        height: 36
        contentItem: Label {
            text: modelData
            color: root.highlightedIndex === index ? theme.primary : theme.textPrimary
            font.family: theme.fontUi
            font.pixelSize: theme.sizeBody
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: root.highlightedIndex === index ? theme.surfaceHover : "transparent"
        }
    }

    contentItem: Label {
        text: root.displayText
        color: theme.textPrimary
        font.family: theme.fontUi
        font.pixelSize: theme.sizeBody
        verticalAlignment: Text.AlignVCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 30
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: theme.radiusControl
        color: mouseArea.containsMouse ? theme.surfaceHover : theme.appBackground
        border.width: root.popup.visible ? 2 : 1
        border.color: root.popup.visible ? theme.primary : theme.border
        
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "▾"
            color: theme.textSecondary
            font.pixelSize: 14
        }
    }

    popup: Popup {
        y: root.height - 1
        width: root.width
        implicitHeight: contentItem.implicitHeight
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }

        background: Rectangle {
            color: theme.surface
            border.color: theme.border
            border.width: 1
            radius: theme.radiusControl
            
            // Drop shadow emulation
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0,0,0,0.1)
                radius: parent.radius
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
