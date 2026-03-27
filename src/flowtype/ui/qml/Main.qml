import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    visible: (typeof StartHidden === "undefined") ? true : !StartHidden
    width: 1420
    height: 840
    minimumWidth: 1220
    minimumHeight: 740
    title: "FlowType"
    color: "#f7fafc"

    property int currentPage: 0
    property int displayedPage: 0
    property bool toastVisible: false
    property string logoSource: "../../assets/branding/logo-mark.png"

    readonly property var navItems: [
        { "label": "Home", "subtitle": "Start dictation and review setup", "accent": "#f97316" },
        { "label": "Modes", "subtitle": "Tune cleanup behavior for writing styles", "accent": "#3b82f6" },
        { "label": "Vocabulary", "subtitle": "Protect names and replacements", "accent": "#10b981" },
        { "label": "History", "subtitle": "Review recent dictations", "accent": "#ec4899" },
        { "label": "Settings", "subtitle": "Shortcuts, cleanup, and recording", "accent": "#0d9488" }
    ]

    function statusColor(value) {
        if (value === "recording")
            return "#f97316"
        if (value === "transcribing" || value === "cleaning" || value === "pasting")
            return "#2563eb"
        if (value === "error")
            return "#ef4444"
        if (value === "ready")
            return "#0d9488"
        return "#64748b"
    }

    Connections {
        target: AppController

        function onNotificationChanged() {
            if (AppController.notificationMessage.length === 0)
                return
            window.toastVisible = true
            toastTimer.restart()
        }
    }

    Timer {
        id: toastTimer
        interval: 3200
        repeat: false
        onTriggered: window.toastVisible = false
    }

    component NavButton : Rectangle {
        property string label: ""
        property color accent: "#0d9488"
        property int pageIndex: 0

        radius: 18
        color: window.currentPage === pageIndex ? Qt.rgba(accent.r, accent.g, accent.b, 0.1) : (navArea.containsMouse ? "#f8fbfd" : "transparent")
        border.width: 1
        border.color: window.currentPage === pageIndex ? Qt.rgba(accent.r, accent.g, accent.b, 0.24) : "transparent"
        scale: navArea.pressed ? 0.988 : 1.0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 12
                color: window.currentPage === pageIndex ? accent : Qt.rgba(accent.r, accent.g, accent.b, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: label.substring(0, 1)
                    color: window.currentPage === pageIndex ? "#ffffff" : "#184056"
                    font.family: "Bahnschrift SemiBold"
                    font.pixelSize: 14
                }
            }

            Label {
                Layout.fillWidth: true
                text: label
                color: window.currentPage === pageIndex ? "#163042" : "#29465b"
                font.family: "Segoe UI Variable Text"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: window.currentPage = pageIndex
        }

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    SequentialAnimation {
        id: pageSwap

        NumberAnimation {
            target: contentStackHost
            property: "opacity"
            to: 0.0
            duration: 90
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: window.displayedPage = window.currentPage
        }
        NumberAnimation {
            target: contentStackHost
            property: "opacity"
            to: 1.0
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    onCurrentPageChanged: {
        if (displayedPage === currentPage)
            return
        pageSwap.restart()
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#fbfdfe" }
            GradientStop { position: 1.0; color: "#f3f7fa" }
        }
    }

    HUDWindow { }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        SurfacePanel {
            Layout.preferredWidth: 196
            Layout.fillHeight: true
            padding: 14
            cornerRadius: 24
            prominent: true
            accent: "#0d9488"
            showOrb: false

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 12
                            color: "#f3f7fb"
                            border.width: 1
                            border.color: "#dde7ee"

                            Image {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                source: window.logoSource
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "FlowType"
                                color: "#163042"
                                font.family: "Segoe UI Variable Display"
                                font.pixelSize: 20
                                font.weight: Font.Black
                            }

                            Label {
                                text: "Local dictation for Windows"
                                color: "#6f8798"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Repeater {
                    model: window.navItems

                    delegate: NavButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        label: modelData.label
                        accent: modelData.accent
                        pageIndex: index
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 9
                        Layout.preferredHeight: 9
                        radius: 4.5
                        color: window.statusColor(AppController.status)
                    }

                    Label {
                        Layout.fillWidth: true
                        text: AppController.status === "ready"
                            ? "Ready for " + AppController.holdToTalk.toUpperCase().split("+").join(" + ")
                            : AppController.detail
                        color: "#60798b"
                        font.family: "Segoe UI Variable Text"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        SurfacePanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            prominent: true
            accent: window.navItems[window.displayedPage].accent
            cornerRadius: 26
            padding: 16
            showOrb: false

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                SurfacePanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68
                    cornerRadius: 20
                    accent: window.navItems[window.displayedPage].accent
                    padding: 14
                    showAccentBar: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: window.navItems[window.displayedPage].label
                                color: "#163042"
                                font.family: "Segoe UI Variable Display"
                                font.pixelSize: 24
                                font.weight: Font.Black
                            }

                            Label {
                                text: window.navItems[window.displayedPage].subtitle
                                color: "#6e8798"
                                font.family: "Segoe UI Variable Text"
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            radius: 16
                            color: "#ffffff"
                            border.width: 1
                            border.color: "#d8e5ec"
                            implicitWidth: statusRow.implicitWidth + 22
                            implicitHeight: 34

                            RowLayout {
                                id: statusRow
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: window.statusColor(AppController.status)
                                }

                                Label {
                                    text: AppController.status === "ready" ? "Ready" : AppController.status.toUpperCase()
                                    color: "#173042"
                                    font.family: "Bahnschrift SemiBold"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        FlowButton {
                            label: "Re-paste"
                            variant: "secondary"
                            onClicked: AppController.repasteLastText()
                        }

                        FlowButton {
                            label: AppController.status === "recording" ? "Stop Dictation" : "Start Dictation"
                            variant: AppController.status === "recording" ? "danger" : "primary"
                            accent: "#2563eb"
                            emphasized: AppController.status === "recording"
                            onClicked: AppController.toggleRecording()
                        }
                    }
                }

                Item {
                    id: contentStackHost
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    opacity: 1.0

                    StackLayout {
                        anchors.fill: parent
                        currentIndex: window.displayedPage

                        HomeView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onNavigateRequested: (index) => window.currentPage = index
                        }

                        ModesView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        VocabularyView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        HistoryView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        SettingsView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }

    OnboardingModal {
        anchors.fill: parent
        z: 30
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 24
        anchors.rightMargin: 24
        radius: 18
        width: Math.min(420, toastLabel.implicitWidth + 50)
        height: 52
        color: AppController.notificationTone === "error" ? "#fff1f0" : (AppController.notificationTone === "success" ? "#e8faf6" : "#eef6fb")
        border.width: 1
        border.color: AppController.notificationTone === "error" ? "#f2b2ab" : (AppController.notificationTone === "success" ? "#96dccf" : "#cfe0eb")
        opacity: window.toastVisible ? 1 : 0
        visible: opacity > 0

        Label {
            id: toastLabel
            anchors.centerIn: parent
            text: AppController.notificationMessage
            color: "#173042"
            font.family: "Segoe UI Variable Text"
            font.pixelSize: 13
        }

        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        y: window.toastVisible ? 24 : 10
    }
}
