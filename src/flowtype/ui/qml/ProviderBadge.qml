import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    Theme { id: theme }

    property string providerId: ""
    property string badgeText: ""
    property color accentColor: theme.textSecondary

    width: 38
    height: 38
    radius: 12
    color: theme.surfaceMuted
    border.width: 1
    border.color: theme.border

    function displayText() {
        if (root.badgeText.length > 0)
            return root.badgeText
        if (root.providerId === "openrouter")
            return "OR"
        if (root.providerId === "openai")
            return "OA"
        if (root.providerId === "anthropic")
            return "CL"
        if (root.providerId === "xai")
            return "XA"
        if (root.providerId === "gemini")
            return "GM"
        if (root.providerId === "groq")
            return "GQ"
        if (root.providerId === "ollama")
            return "OL"
        return "FT"
    }

    Label {
        anchors.centerIn: parent
        text: root.displayText()
        color: root.accentColor
        font.family: theme.fontUi
        font.pixelSize: 11
        font.weight: 700
        opacity: root.providerId === "none" ? 0.5 : 1.0
    }
}
