import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    Theme { id: theme }

    property string providerId: ""
    property string badgeText: ""
    property color accentColor: theme.textSecondary

    width: 40
    height: 40
    radius: 12
    color: theme.darkMode ? "#161B22" : "#F4F6FB"
    border.width: 1
    border.color: theme.border

    function displayText() {
        if (root.badgeText && root.badgeText.length > 0)
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
        font.family: theme.fontDisplay
        font.pixelSize: 14
        font.weight: Font.Bold
        opacity: root.providerId === "none" ? 0.5 : 1.0
    }
}
