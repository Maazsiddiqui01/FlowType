import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    Theme { id: theme }

    visible: typeof StartHidden !== "undefined" ? !StartHidden : true
    title: "FlowType"
    width: 1180
    height: 760
    minimumWidth: 860
    minimumHeight: 600
    color: theme.appBackground

    property int currentPage: 0
    property string notificationMessage: ""
    property string notificationTone: "info"
    property bool notificationVisible: false

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
        interval: 3200
        onTriggered: window.notificationVisible = false
    }

    // ── App Shell ────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Sidebar ──────────────────────────────────────
        Rectangle {
            id: sidebar
            Layout.preferredWidth: theme.railWidth
            Layout.fillHeight: true
            color: theme.darkMode ? "#0E1119" : "#FFFFFF"
            z: 1

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: theme.space12
                spacing: 0

                // ── Logo / Brand ─────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: theme.space12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.space8

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 8
                            color: theme.primary
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                anchors.centerIn: parent
                                text: "F"
                                color: "#ffffff"
                                font.family: theme.fontDisplay
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                        }

                        Label {
                            text: "FlowType"
                            color: theme.textPrimary
                            font.family: theme.fontDisplay
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Item { Layout.preferredHeight: theme.space8 }

                // ── Navigation ───────────────────────────
                Repeater {
                    model: [
                        { label: "Home",       icon: "⌂", page: 0 },
                        { label: "Cleanup",    icon: "⚗", page: 1 },
                        { label: "Modes",      icon: "◉", page: 2 },
                        { label: "Vocabulary",  icon: "✦", page: 3 },
                        { label: "History",    icon: "↻", page: 4 },
                        { label: "Recording",  icon: "◎", page: 5 },
                        { label: "Settings",   icon: "⚙", page: 6 }
                    ]

                    delegate: Rectangle {
                        id: navItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: theme.railItemHeight
                        radius: theme.radiusControl
                        color: window.currentPage === modelData.page
                            ? (theme.darkMode ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                            : (navMouseArea.containsMouse
                                ? (theme.darkMode ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.02))
                                : "transparent")

                        // Active indicator bar
                        Rectangle {
                            visible: window.currentPage === modelData.page
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 20
                            radius: 2
                            color: theme.primary
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: theme.space12

                            Label {
                                text: modelData.icon
                                color: window.currentPage === modelData.page ? theme.primary : theme.textSecondary
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                text: modelData.label
                                color: window.currentPage === modelData.page ? theme.textPrimary : theme.textSecondary
                                font.family: theme.fontText
                                font.pixelSize: theme.sizeBody
                                font.weight: window.currentPage === modelData.page ? Font.DemiBold : Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: navMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentPage = modelData.page
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Item { Layout.fillHeight: true }

                // ── Bottom controls ──────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: theme.border
                }

                Item { Layout.preferredHeight: theme.space8 }

                // Dark mode toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.railItemHeight
                    radius: theme.radiusControl
                    color: darkToggleArea.containsMouse
                        ? (theme.darkMode ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.02))
                        : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: theme.space12

                        Label {
                            text: theme.darkMode ? "☾" : "☀"
                            color: theme.textSecondary
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Label {
                            text: theme.darkMode ? "Dark" : "Light"
                            color: theme.textSecondary
                            font.family: theme.fontText
                            font.pixelSize: theme.sizeBody
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: darkToggleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AppController.toggleDarkMode()
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Status pill
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: theme.radiusPill
                    color: theme.darkMode ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)

                    Row {
                        anchors.centerIn: parent
                        spacing: theme.space8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                var s = AppController.status
                                if (s === "ready") return theme.success
                                if (s === "recording") return theme.warm
                                if (s === "error") return theme.error
                                return theme.textTertiary
                            }

                            SequentialAnimation on opacity {
                                running: AppController.status === "recording"
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            }
                        }

                        Label {
                            text: {
                                var s = AppController.status
                                if (s === "ready") return "Ready"
                                if (s === "recording") return "Recording"
                                if (s === "transcribing") return "Transcribing"
                                if (s === "cleaning") return "Cleaning"
                                if (s === "pasting") return "Pasting"
                                if (s === "starting") return "Starting"
                                if (s === "error") return "Error"
                                return s
                            }
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.sizeLabel
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // ── Content area ─────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                anchors.fill: parent
                anchors.margins: theme.shellPadding
                currentIndex: window.currentPage

                HomeView        { Layout.fillWidth: true; Layout.fillHeight: true }
                ConfigurationView { Layout.fillWidth: true; Layout.fillHeight: true }
                ModesView       { Layout.fillWidth: true; Layout.fillHeight: true }
                VocabularyView  { Layout.fillWidth: true; Layout.fillHeight: true }
                HistoryView     { Layout.fillWidth: true; Layout.fillHeight: true }
                SoundView       { Layout.fillWidth: true; Layout.fillHeight: true }
                SettingsView    { Layout.fillWidth: true; Layout.fillHeight: true }
            }

            // ── Toast notification ───────────────────────
            Rectangle {
                id: toastBanner
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: window.notificationVisible ? theme.space12 : -60
                width: Math.min(400, toastLabel.implicitWidth + 40)
                height: 42
                radius: theme.radiusPill
                color: theme.surface
                border.width: 1
                border.color: theme.border
                opacity: window.notificationVisible ? 1.0 : 0.0
                z: 100

                Behavior on anchors.topMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Label {
                    id: toastLabel
                    anchors.centerIn: parent
                    text: window.notificationMessage
                    color: theme.textPrimary
                    font.family: theme.fontUi
                    font.pixelSize: theme.sizeBody
                    font.weight: Font.Medium
                }
            }
        }
    }

    // ── Onboarding modal ─────────────────────────────────
    OnboardingModal {
        anchors.fill: parent
        z: 200
        visible: !AppController.onboardingDismissed
    }
}
