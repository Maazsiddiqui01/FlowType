import QtQuick

Column {
    id: root
    
    Theme { id: theme }
    
    property string title: ""
    property string subtitle: ""
    
    width: parent.width
    spacing: theme.space4
    
    Label {
        text: root.title
        color: theme.textPrimary
        font.family: theme.fontDisplay
        font.pixelSize: theme.sizeSectionTitle
        font.weight: Font.DemiBold
    }
    
    Label {
        visible: root.subtitle.length > 0
        text: root.subtitle
        color: theme.textSecondary
        font.family: theme.fontText
        font.pixelSize: theme.sizeBody
        wrapMode: Text.WordWrap
        width: parent.width
    }
}
