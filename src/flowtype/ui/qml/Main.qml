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
        { "label": "Home", "icon": "house", "title": "Home", "subtitle": "Dictate, clean, and paste with less friction." },
        { "label": "AI Models", "icon": "sparkles", "title": "AI Models", "subtitle": "Choose the provider, model, and cleanup behavior." },
        { "label": "Modes", "icon": "sliders_horizontal", "title": "Modes", "subtitle": "Tune the cleanup style for the way you work." },
        { "label": "Dictionary", "icon": "book_open", "title": "Dictionary", "subtitle": "Teach FlowType your names, brands, and spellings." },
        { "label": "History", "icon": "history", "title": "History", "subtitle": "Review recent output and fallback behavior." },
        { "label": "Recording", "icon": "mic", "title": "Recording", "subtitle": "Adjust the HUD and capture timing." },
        { "label": "Settings", "icon": "settings", "title": "Settings", "subtitle": "Shortcuts, startup behavior, and app support." }
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

    // Designed glass backdrop: a vertical gradient plus two soft accent glows that
    // give frosted surfaces something to refract. Always painted, so dark mode is
    // always dark (no reliance on the OS Mica material, which renders inconsistently).
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.appGradientTop }
            GradientStop { position: 1.0; color: theme.appGradientBottom }
        }

        // Top-left primary glow
        Rectangle {
            width: parent.width * 0.7
            height: parent.height * 0.7
            x: -parent.width * 0.22
            y: -parent.height * 0.28
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: theme.glowPrimary }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Bottom-right teal glow
        Rectangle {
            width: parent.width * 0.6
            height: parent.height * 0.6
            x: parent.width * 0.62
            y: parent.height * 0.5
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: theme.glowTeal }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: rail
            Layout.preferredWidth: theme.railWidth
            Layout.fillHeight: true
            color: theme.darkMode ? "#0B0F18" : "#F7FAFE"

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

                // Brand row: flat, no card box — the rail itself is the surface.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    Layout.leftMargin: 6
                    spacing: theme.space12

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 11
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: theme.tint(theme.primary, 0.92) }
                            GradientStop { position: 1.0; color: theme.primary }
                        }

                        // Mini waveform mark (matches the recording pill identity)
                        Row {
                            anchors.centerIn: parent
                            spacing: 2.5

                            Repeater {
                                model: [7, 13, 17, 10, 6]
                                delegate: Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 2.5
                                    height: modelData
                                    radius: 1.25
                                    color: "#FFFFFF"
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            text: "FlowType"
                            color: theme.textPrimary
                            font.family: theme.fontDisplay
                            font.pixelSize: theme.sizeAppTitle
                            font.weight: 760
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Local-first dictation"
                            color: theme.textTertiary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeLabel
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.bottomMargin: theme.space8
                    color: theme.divider
                }

                Repeater {
                    model: window.pages

                    delegate: Rectangle {
                        id: navItem
                        readonly property bool navActive: window.currentPage === index

                        Layout.fillWidth: true
                        Layout.preferredHeight: theme.railItemHeight
                        radius: theme.radiusControl
                        color: navActive
                            ? theme.tint(theme.primary, theme.darkMode ? 0.16 : 0.09)
                            : (navArea.containsMouse ? theme.surfaceHover : "transparent")
                        border.width: 1
                        border.color: navActive
                            ? theme.tint(theme.primary, theme.darkMode ? 0.36 : 0.22)
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible: navItem.navActive
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 16
                            radius: 1.5
                            color: theme.primary
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 11

                            NavIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: modelData.icon
                                size: 17
                                strokeWidth: navItem.navActive ? 2.2 : 1.8
                                color: navItem.navActive ? theme.primary : theme.textTertiary
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: navItem.navActive ? theme.textPrimary : theme.textSecondary
                                font.family: theme.fontUi
                                font.pixelSize: theme.sizeBody
                                font.weight: navItem.navActive ? 650 : 500
                            }
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
                    Layout.preferredHeight: 34
                    radius: theme.radiusPill
                    color: theme.tint(window.statusTone(), theme.darkMode ? 0.10 : 0.07)
                    border.width: 1
                    border.color: theme.tint(window.statusTone(), theme.darkMode ? 0.28 : 0.20)

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: theme.space8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 7
                            height: 7
                            radius: 3.5
                            color: window.statusTone()
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
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
