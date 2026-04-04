import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    Theme { id: theme }

    property string shortcut: ""
    property string actionName: ""
    property bool isRecording: captureActive
    signal shortcutRecorded(string newShortcut)

    property bool captureActive: false
    property var pendingModifierParts: []

    onCaptureActiveChanged: {
        if (!captureActive) {
            modifierOnlyTimer.stop()
            pendingModifierParts = []
        }
    }

    implicitWidth: 360
    implicitHeight: theme.controlHeight

    function modifierParts(modifiers) {
        var parts = []
        if (modifiers & Qt.ControlModifier) parts.push("ctrl")
        if (modifiers & Qt.AltModifier) parts.push("alt")
        if (modifiers & Qt.ShiftModifier) parts.push("shift")
        if (modifiers & Qt.MetaModifier) parts.push("meta")
        return parts
    }

    function keyName(key) {
        if (key === Qt.Key_Space) return "space"
        if (key === Qt.Key_Escape) return "escape"
        if (key === Qt.Key_Return || key === Qt.Key_Enter) return "enter"
        if (key === Qt.Key_Tab) return "tab"
        if (key === Qt.Key_Backspace) return "backspace"
        if (key === Qt.Key_Delete) return "delete"
        if (key === Qt.Key_Insert) return "insert"
        if (key === Qt.Key_Home) return "home"
        if (key === Qt.Key_End) return "end"
        if (key === Qt.Key_PageUp) return "pageup"
        if (key === Qt.Key_PageDown) return "pagedown"
        if (key === Qt.Key_Up) return "up"
        if (key === Qt.Key_Down) return "down"
        if (key === Qt.Key_Left) return "left"
        if (key === Qt.Key_Right) return "right"
        if (key === Qt.Key_Comma) return "comma"
        if (key === Qt.Key_Period) return "period"
        if (key === Qt.Key_Slash) return "slash"
        if (key === Qt.Key_Backslash) return "backslash"
        if (key === Qt.Key_Minus) return "-"
        if (key === Qt.Key_Equal) return "="
        if (key === Qt.Key_BracketLeft) return "["
        if (key === Qt.Key_BracketRight) return "]"
        if (key === Qt.Key_Semicolon) return "semicolon"
        if (key === Qt.Key_Apostrophe) return "apostrophe"
        if (key >= Qt.Key_F1 && key <= Qt.Key_F12) return "f" + (key - Qt.Key_F1 + 1)
        if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key).toLowerCase()
        if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key)
        return ""
    }

    function captureShortcut(event) {
        var name = keyName(event.key)
        var modifiers = modifierParts(event.modifiers)
        if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift || event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
            root.pendingModifierParts = modifiers
            modifierOnlyTimer.restart()
            return
        }
        if (name.length === 0)
            return
        modifierOnlyTimer.stop()
        root.pendingModifierParts = []
        var parts = modifiers
        parts.push(name)
        root.captureActive = false
        root.shortcutRecorded(parts.join("+"))
    }

    Keys.onPressed: function(event) {
        if (!root.captureActive)
            return
        event.accepted = true
        if (event.key === Qt.Key_Escape && root.actionName !== "cancel_recording") {
            modifierOnlyTimer.stop()
            root.pendingModifierParts = []
            root.captureActive = false
            return
        }
        root.captureShortcut(event)
    }

    Timer {
        id: modifierOnlyTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (!root.captureActive || root.pendingModifierParts.length < 2)
                return
            root.captureActive = false
            root.shortcutRecorded(root.pendingModifierParts.join("+"))
            root.pendingModifierParts = []
        }
    }

    Rectangle {
        id: shell
        anchors.fill: parent
        radius: theme.radiusControl
        color: root.captureActive ? theme.tint(theme.primary, theme.darkMode ? 0.16 : 0.08) : theme.surface
        border.width: 1
        border.color: root.captureActive ? theme.tint(theme.primary, theme.darkMode ? 0.55 : 0.3) : theme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: theme.space12
            anchors.rightMargin: theme.space12
            spacing: theme.space8

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: root.captureActive ? theme.primary : theme.borderSelected

                SequentialAnimation on opacity {
                    running: root.captureActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            Label {
                Layout.fillWidth: true
                text: {
                    if (root.captureActive)
                        return "Press a key or combo"
                    if (root.shortcut.length > 0)
                        return root.shortcut.toUpperCase().replace(/\+/g, "  +  ")
                    return "Click and press a key"
                }
                color: root.captureActive ? theme.textPrimary : (root.shortcut.length > 0 ? theme.textPrimary : theme.textTertiary)
                font.family: theme.fontUi
                font.pixelSize: theme.sizeBody
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.captureActive = true
            root.forceActiveFocus()
        }
    }
}
