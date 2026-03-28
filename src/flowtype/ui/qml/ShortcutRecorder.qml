import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Theme { id: theme }

    property string currentShortcut: ""
    property bool isRecording: false
    property bool requireModifier: true
    property string idleText: "Click to set shortcut"
    property string feedbackMessage: ""

    signal shortcutRecorded(string newShortcut)

    implicitWidth: 300
    implicitHeight: theme.buttonHeight

    function formatToken(token) {
        if (!token)
            return ""
        var value = token.toLowerCase()
        if (value === "ctrl")
            return "Ctrl"
        if (value === "shift")
            return "Shift"
        if (value === "alt")
            return "Alt"
        if (value === "meta" || value === "cmd" || value === "super")
            return "Win"
        if (value === "space")
            return "Space"
        if (value === "enter" || value === "return")
            return "Enter"
        if (value === "escape" || value === "esc")
            return "Esc"
        return token.charAt(0).toUpperCase() + token.slice(1)
    }

    function modifierCount(parts) {
        var count = 0
        for (var i = 0; i < parts.length; i += 1) {
            if (parts[i] === "ctrl" || parts[i] === "alt" || parts[i] === "shift" || parts[i] === "meta")
                count += 1
        }
        return count
    }

    function mainKeyCount(parts) {
        return parts.length - modifierCount(parts)
    }

    function normalizeParts(parts) {
        var modifierOrder = ["ctrl", "alt", "shift", "meta"]
        var normalized = []
        for (var i = 0; i < modifierOrder.length; i += 1) {
            if (parts.indexOf(modifierOrder[i]) >= 0)
                normalized.push(modifierOrder[i])
        }
        for (var j = 0; j < parts.length; j += 1) {
            if (modifierOrder.indexOf(parts[j]) < 0)
                normalized.push(parts[j])
        }
        return normalized
    }

    function validationMessage(parts) {
        if (mainKeyCount(parts) !== 1)
            return "Use one main key"
        if (requireModifier && modifierCount(parts) === 0)
            return "Use Ctrl, Alt, Shift, or Win"
        return ""
    }

    function commitShortcut(parts) {
        parts = normalizeParts(parts)
        var message = validationMessage(parts)
        if (message.length > 0) {
            root.feedbackMessage = message
            clearFeedbackTimer.restart()
            return
        }

        root.currentShortcut = parts.join("+")
        root.isRecording = false
        root.feedbackMessage = ""
        root.shortcutRecorded(root.currentShortcut)
        focusScope.focus = false
    }

    function processKeyEvent(event) {
        var parts = []

        if (event.modifiers & Qt.ControlModifier)
            parts.push("ctrl")
        if (event.modifiers & Qt.AltModifier)
            parts.push("alt")
        if (event.modifiers & Qt.ShiftModifier)
            parts.push("shift")
        if (event.modifiers & Qt.MetaModifier)
            parts.push("meta")

        var k = event.key
        if (k === Qt.Key_Control || k === Qt.Key_Alt || k === Qt.Key_Shift || k === Qt.Key_Meta)
            return

        if (k === Qt.Key_Space)
            parts.push("space")
        else if (k === Qt.Key_Tab)
            parts.push("tab")
        else if (k === Qt.Key_Enter || k === Qt.Key_Return)
            parts.push("enter")
        else if (k === Qt.Key_Escape)
            parts.push("escape")
        else if (k >= Qt.Key_A && k <= Qt.Key_Z)
            parts.push(String.fromCharCode(k).toLowerCase())
        else if (k >= Qt.Key_0 && k <= Qt.Key_9)
            parts.push(String.fromCharCode(k))
        else if (k >= Qt.Key_F1 && k <= Qt.Key_F12)
            parts.push("f" + (k - Qt.Key_F1 + 1))
        else if (event.text !== "")
            parts.push(event.text.toLowerCase())
        else
            return

        event.accepted = true
        commitShortcut(parts)
    }

    Timer {
        id: clearFeedbackTimer
        interval: 1600
        repeat: false
        onTriggered: root.feedbackMessage = ""
    }

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusControl
        color: root.isRecording ? theme.tint(theme.primary, 0.07) : theme.surface
        border.width: 1
        border.color: root.feedbackMessage.length > 0 ? theme.error : (root.isRecording ? theme.tint(theme.primary, 0.5) : theme.border)

        FocusScope {
            id: focusScope
            anchors.fill: parent

            Keys.onPressed: (event) => {
                if (!root.isRecording)
                    return
                if (event.key === Qt.Key_Escape && root.requireModifier) {
                    root.isRecording = false
                    root.feedbackMessage = ""
                    event.accepted = true
                    focus = false
                    return
                }
                root.processKeyEvent(event)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    focusScope.forceActiveFocus()
                    root.isRecording = true
                    root.feedbackMessage = ""
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: theme.space12
                spacing: theme.space8

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.feedbackMessage.length > 0 ? theme.error : (root.isRecording ? theme.primary : theme.border)
                }

                Label {
                    visible: root.isRecording
                    text: root.feedbackMessage.length > 0 ? root.feedbackMessage : "Press the full shortcut"
                    color: root.feedbackMessage.length > 0 ? Qt.darker(theme.error, 1.08) : theme.textPrimary
                    font.family: theme.fontUi
                    font.pixelSize: theme.textBody
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Label {
                    visible: !root.isRecording && root.currentShortcut.length === 0
                    text: root.feedbackMessage.length > 0 ? root.feedbackMessage : root.idleText
                    color: root.feedbackMessage.length > 0 ? Qt.darker(theme.error, 1.08) : theme.textTertiary
                    font.family: theme.fontUi
                    font.pixelSize: theme.textBody
                    font.weight: root.feedbackMessage.length > 0 ? Font.DemiBold : Font.Normal
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Label {
                    visible: !root.isRecording && root.currentShortcut.length > 0 && root.feedbackMessage.length > 0
                    text: root.feedbackMessage
                    color: Qt.darker(theme.error, 1.08)
                    font.family: theme.fontUi
                    font.pixelSize: theme.textBody
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Flow {
                    visible: !root.isRecording && root.currentShortcut.length > 0 && root.feedbackMessage.length === 0
                    Layout.fillWidth: true
                    spacing: theme.space4

                    Repeater {
                        model: !root.isRecording && root.currentShortcut.length > 0 ? root.currentShortcut.split("+") : []

                        delegate: Rectangle {
                            radius: 11
                            color: theme.surfaceSubtle
                            border.width: 1
                            border.color: theme.border
                            implicitWidth: keyText.implicitWidth + 14
                            implicitHeight: 24

                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: root.formatToken(modelData)
                                color: theme.textPrimary
                                font.family: theme.fontUi
                                font.weight: Font.DemiBold
                                font.pixelSize: theme.textLabel
                            }
                        }
                    }
                }

                Label {
                    visible: root.isRecording
                    text: "Esc to cancel"
                    color: theme.textTertiary
                    font.family: theme.fontUi
                    font.pixelSize: theme.textLabel
                }
            }
        }
    }
}
