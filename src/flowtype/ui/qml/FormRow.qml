import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    
    Theme { id: theme }
    
    property string title: ""
    property string subtitle: ""
    property string detail: ""
    default property alias content: controlContainer.data
    
    spacing: theme.space16
    
    Column {
        Layout.fillWidth: true
        spacing: theme.space4
        
        Label {
            text: root.title
            color: theme.textPrimary
            font.family: theme.fontText
            font.pixelSize: theme.sizeCardTitle
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: parent.width
        }
        
        Label {
            visible: (root.subtitle.length > 0) || (root.detail.length > 0)
            text: root.subtitle.length > 0 ? root.subtitle : root.detail
            color: theme.textSecondary
            font.family: theme.fontText
            font.pixelSize: theme.sizeHelper
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }
    
    Item {
        id: controlContainer
        Layout.minimumWidth: childrenRect.width
        Layout.preferredWidth: childrenRect.width
        Layout.preferredHeight: childrenRect.height
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }
}
