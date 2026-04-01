import QtQuick
import QtQuick.Controls

Item {
    id: root
    
    Theme { id: theme }
    
    property bool checked: false
    signal clicked()
    signal toggled(bool checked)
    
    width: 44
    height: 24
    
    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? theme.primary : (theme.darkMode ? "#2C3440" : "#DDE2EA")
        border.width: 1
        border.color: root.checked ? theme.primary : theme.border
        
        Rectangle {
            id: thumb
            width: 18
            height: 18
            radius: 9
            color: "#FFFFFF"
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? (parent.width - width - 3) : 3
            
            // Subtle drop shadow for the thumb
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0,0,0,0.1)
                z: -1
            }
            
            Behavior on x {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }
        }
        
        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on border.color { ColorAnimation { duration: 250 } }
    }
    
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
            root.clicked()
        }
    }
}
