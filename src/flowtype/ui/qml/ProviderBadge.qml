import QtQuick

Rectangle {
    id: root
    
    Theme { id: theme }
    
    property string providerId: ""
    property color accentColor: theme.textSecondary
    
    width: 40
    height: 40
    radius: 12
    color: theme.darkMode ? "#161B22" : "#F4F6FB"
    border.width: 1
    border.color: theme.border
    
    Label {
        anchors.centerIn: parent
        text: {
            if (providerId === "openrouter") return "O"
            if (providerId === "openai") return "O"
            if (providerId === "anthropic") return "A"
            if (providerId === "xai") return "X"
            if (providerId === "gemini") return "G"
            if (providerId === "groq") return "G"
            if (providerId === "ollama") return "🦙"
            return "⌨️"
        }
        color: root.accentColor
        font.family: theme.fontDisplay
        font.pixelSize: 18
        font.weight: Font.Bold
        opacity: providerId === "none" ? 0.5 : 1.0
    }
}
