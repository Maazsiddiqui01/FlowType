import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    Theme { id: theme }

    visible: typeof StartHidden !== "undefined" ? !StartHidden : true
    title: "FlowType"
    width: 1220
    height: 820
    minimumWidth: 980
    minimumHeight: 680
    color: theme.appBackground

    property int currentPage: 0
    property string notificationMessage: ""
    property string notificationTone: "info"
    property bool notificationVisible: false

    readonly property var pages: [
        { "label": "Home", "title": "Home", "subtitle": "Dictate, clean, and paste with less friction." },
        { "label": "Cleanup", "title": "Cleanup", "subtitle": "Choose the provider, model, and cleanup behavior." },
        { "label": "Modes", "title": "Modes", "subtitle": "Tune the cleanup style for the way you work." },
        { "label": "Vocabulary", "title": "Vocabulary", "subtitle": "Protect names, brands, acronyms, and spellings." },
        { "label": "History", "title": "History", "subtitle": "Review recent output and fallback behavior." },
        { "label": "Recording", "title": "Recording", "subtitle": "Adjust the HUD and capture timing." },
        { "label": "Settings", "title": "Settings", "subtitle": "Shortcuts, startup behavior, and app support." }
    ]

    function currentPageMeta() {
        return pages[Math.max(0, Math.min(pages.length - 1, currentPage))]
    }

    function statusTone() {
        if (AppController.status === "ready") return theme.success
        if (AppController.status === "recording") return theme.warm
        if (AppController.status === "transcribing" || AppController.status === "cleaning" || AppController.status === "pasting") return theme.primary
        if (AppController.status === "error") return theme.error
        return theme.textTertiary
    }

    function statusLabel() {
        if (AppController.status === "recording") return "Recording"
        if (AppController.status === "transcribing") return "Transcribing"
        if (AppController.status === "cleaning") return "Cleaning"
        if (AppController.status === "pasting") return "Pasting"
        if (AppController.status === "error") return "Error"
        if (AppController.status === "starting") return "Starting"
        return "Ready"
    }

    Connections {
        target: AppController

        function onNotificationChanged() {
            window.notificationMessage = AppController.notificationMessage
            window.notificationTone = AppController.notificationTone
            if (window.notificationMessage.length > 0) {
                window.notificationVisible = true
                notificationTimer.restart()
            }
        }
    }

    Timer {
        id: notificationTimer
        interval: 2800
        onTriggered: window.notificationVisible = false
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: rail
            Layout.preferredWidth: theme.railWidth
            Layout.fillHeight: true
            color: theme.darkMode ? "#0D121B" : "#FBFCFE"

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: theme.space16
                spacing: theme.space8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: theme.radiusCard
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: theme.space12
                        spacing: theme.space12

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 12
                            color: theme.primary

                            Label {
                                anchors.centerIn: parent
                                text: "F"
                                color: "#FFFFFF"
                                font.family: theme.fontDisplay
                                font.pixelSize: 16
                                font.weight: 760
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Label {
                                text: "FlowType"
                                color: theme.textPrimary
                                font.family: theme.fontDisplay
                                font.pixelSize: theme.sizeAppTitle
                                font.weight: 760
                            }

                            Label {
                                text: "Desktop dictation, cleaned locally first."
                                color: theme.textSecondary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeHelper
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: theme.space12 }

                Repeater {
                    model: window.pages

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: theme.railItemHeight
                        radius: theme.radiusControl
                        color: window.currentPage === index
                            ? theme.tint(theme.primary, theme.darkMode ? 0.18 : 0.09)
                            : (navArea.containsMouse ? theme.surfaceHover : "transparent")
                        border.width: 1
                        border.color: window.currentPage === index
                            ? theme.tint(theme.primary, theme.darkMode ? 0.38 : 0.22)
                            : "transparent"

                        Rectangle {
                            visible: window.currentPage === index
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: 18
                            radius: 2
                            color: theme.primary
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: window.currentPage === index ? theme.textPrimary : theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.sizeBody
                            font.weight: window.currentPage === index ? 650 : 500
                        }

                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentPage = index
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: theme.divider
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: theme.space12

                    Label {
                        text: theme.darkMode ? "Dark" : "Light"
                        color: theme.textSecondary
                        font.family: theme.fontUi
                        font.pixelSize: theme.sizeHelper
                    }

                    Item { Layout.fillWidth: true }

                    FlowSwitch {
                        checked: theme.darkMode
                        onClicked: AppController.toggleDarkMode()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: theme.radiusPill
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    Row {
                        anchors.centerIn: parent
                        spacing: theme.space8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: window.statusTone()
                        }

                        Label {
                            text: window.statusLabel()
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.sizeLabel
                            font.weight: 650
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: theme.shellPadding
                spacing: theme.space20

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: theme.radiusShell
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: theme.space20
                        spacing: theme.space16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: window.currentPageMeta().title
                                color: theme.textPrimary
                                font.family: theme.fontDisplay
                                font.pixelSize: theme.sizePageTitle
                                font.weight: 760
                            }

                            Label {
                                text: window.currentPageMeta().subtitle
                                color: theme.textSecondary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeHelper
                                elide: Text.ElideRight
                            }
                        }

                        StatusPill {
                            text: window.statusLabel()
                            tone: window.statusTone()
                        }

                        FlowButton {
                            label: "Re-paste"
                            variant: "secondary"
                            buttonEnabled: AppController.historyItems.length > 0
                            onClicked: AppController.repasteLastText()
                        }

                        FlowButton {
                            label: AppController.status === "recording" ? "Stop Dictation" : "Start Dictation"
                            variant: "primary"
                            buttonEnabled: AppController.status !== "starting"
                            onClicked: AppController.toggleRecording()
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: window.currentPage

                    HomeView { Layout.fillWidth: true; Layout.fillHeight: true }
                    ConfigurationView { Layout.fillWidth: true; Layout.fillHeight: true }
                    ModesView { Layout.fillWidth: true; Layout.fillHeight: true }
                    VocabularyView { Layout.fillWidth: true; Layout.fillHeight: true }
                    HistoryView { Layout.fillWidth: true; Layout.fillHeight: true }
                    SoundView { Layout.fillWidth: true; Layout.fillHeight: true }
                    SettingsView { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }

            Rectangle {
                id: toastBanner
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: window.notificationVisible ? theme.space16 : -72
                width: Math.min(460, toastLabel.implicitWidth + 42)
                height: 40
                radius: theme.radiusPill
                color: theme.surface
                border.width: 1
                border.color: window.notificationTone === "error" ? theme.tint(theme.error, 0.28) : theme.border
                opacity: window.notificationVisible ? 1.0 : 0.0
                z: 100

                Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Label {
                    id: toastLabel
                    anchors.centerIn: parent
                    text: window.notificationMessage
                    color: theme.textPrimary
                    font.family: theme.fontUi
                    font.pixelSize: theme.sizeBody
                    font.weight: 600
                }
            }
        }
    }

    OnboardingModal {
        anchors.fill: parent
        z: 200
        visible: AppController.onboardingVisible
    }
}
