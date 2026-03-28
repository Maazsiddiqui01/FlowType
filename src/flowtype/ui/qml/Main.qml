import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    Theme { id: theme }

    visible: (typeof StartHidden === "undefined") ? true : !StartHidden
    width: 1360
    height: 820
    minimumWidth: 1180
    minimumHeight: 760
    title: "FlowType"
    color: theme.appBackground

    property int currentPage: 0
    property int displayedPage: 0
    property bool toastVisible: false
    property string logoSource: "../../../../assets/branding/logo-mark.svg"

    readonly property var navItems: [
        { "label": "Home", "subtitle": "Start dictation and review setup", "accent": "#F59E0B" },
        { "label": "Modes", "subtitle": "Tune cleanup behavior for different writing styles", "accent": "#2F6BFF" },
        { "label": "Vocabulary", "subtitle": "Protect terms, names, and replacements", "accent": "#13A88A" },
        { "label": "History", "subtitle": "Review recent dictation results", "accent": "#E25C52" },
        { "label": "Settings", "subtitle": "Shortcuts, cleanup, and recording behavior", "accent": "#139B93" }
    ]

    function currentItem() {
        return navItems[displayedPage]
    }

    function statusTone(value) {
        if (value === "recording")
            return theme.warm
        if (value === "transcribing" || value === "cleaning" || value === "pasting")
            return theme.primary
        if (value === "error")
            return theme.error
        if (value === "ready")
            return theme.success
        return theme.textTertiary
    }

    function statusLabel(value) {
        if (value === "ready")
            return "Ready"
        if (value === "recording")
            return "Listening"
        if (value === "transcribing")
            return "Transcribing"
        if (value === "cleaning")
            return "Cleaning"
        if (value === "pasting")
            return "Pasting"
        if (value === "error")
            return "Error"
        return value
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
        id: navButton

        property string label: ""
        property color accent: theme.primary
        property int pageIndex: 0

        implicitHeight: theme.railItemHeight
        radius: 14
        color: window.currentPage === pageIndex
            ? theme.tint(accent, 0.11)
            : (navArea.containsMouse ? theme.surfaceSubtle : "transparent")
        border.width: 1
        border.color: window.currentPage === pageIndex ? theme.tint(accent, 0.28) : "transparent"
        scale: navArea.pressed ? 0.988 : 1.0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: theme.space12

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 9
                color: window.currentPage === pageIndex ? accent : theme.tint(accent, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: label.substring(0, 1)
                    color: window.currentPage === pageIndex ? "#ffffff" : accent
                    font.family: theme.fontUi
                    font.pixelSize: theme.textLabel
                    font.weight: Font.DemiBold
                }
            }

            Label {
                Layout.fillWidth: true
                text: label
                color: window.currentPage === pageIndex ? theme.textPrimary : "#244154"
                font.family: theme.fontUi
                font.pixelSize: theme.textBody
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: navArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: window.currentPage = pageIndex
        }

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
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
        color: theme.appBackground
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: theme.shellPadding
        spacing: theme.space16

        SectionCard {
            Layout.preferredWidth: 196
            Layout.fillHeight: true
            padding: 12
            cornerRadius: theme.radiusShell

            ColumnLayout {
                anchors.fill: parent
                spacing: theme.space8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 16
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.divider

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 12
                            color: theme.surface
                            border.width: 1
                            border.color: theme.border

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: window.logoSource
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "FlowType"
                                color: theme.textPrimary
                                font.family: theme.fontDisplay
                                font.pixelSize: theme.sizeAppTitle
                                font.weight: Font.Black
                            }

                            Label {
                                text: "Local dictation for Windows"
                                color: theme.textTertiary
                                font.family: theme.fontUi
                                font.pixelSize: theme.textLabel
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Repeater {
                    model: window.navItems

                    delegate: NavButton {
                        Layout.fillWidth: true
                        label: modelData.label
                        accent: modelData.accent
                        pageIndex: index
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: footerText.implicitHeight + 18
                    radius: 14
                    color: theme.surfaceSubtle
                    border.width: 1
                    border.color: theme.divider

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: theme.space8

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 3
                            width: 7
                            height: 7
                            radius: 4
                            color: window.statusTone(AppController.status)
                        }

                        Label {
                            id: footerText
                            Layout.fillWidth: true
                            text: AppController.status === "ready"
                                ? "Ready for " + AppController.holdToTalk.toUpperCase().split("+").join(" + ")
                                : AppController.detail
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textLabel
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: theme.space16

            SectionCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                padding: 16
                cornerRadius: theme.radiusShell

                RowLayout {
                    anchors.fill: parent
                    spacing: theme.space16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: window.currentItem().label
                            color: theme.textPrimary
                            font.family: theme.fontDisplay
                            font.pixelSize: theme.sizePageTitle
                            font.weight: Font.Black
                        }

                        Label {
                            text: window.currentItem().subtitle
                            color: theme.textSecondary
                            font.family: theme.fontUi
                            font.pixelSize: theme.textHelper
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        spacing: theme.space12

                        StatusPill {
                            statusText: window.statusLabel(AppController.status)
                            tone: window.statusTone(AppController.status)
                        }

                        FlowButton {
                            label: "Re-paste"
                            variant: "secondary"
                            compact: false
                            onClicked: AppController.repasteLastText()
                        }

                        FlowButton {
                            label: AppController.status === "recording" ? "Stop Dictation" : "Start Dictation"
                            variant: AppController.status === "recording" ? "danger" : "primary"
                            accent: theme.primary
                            emphasized: AppController.status === "recording"
                            onClicked: AppController.toggleRecording()
                        }
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

    OnboardingModal {
        anchors.fill: parent
        z: 30
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 22
        anchors.rightMargin: 22
        radius: theme.radiusControl
        width: Math.min(420, toastLabel.implicitWidth + 48)
        height: 46
        color: AppController.notificationTone === "error"
            ? theme.tint(theme.error, 0.08)
            : (AppController.notificationTone === "success"
                ? theme.tint(theme.success, 0.08)
                : theme.tint(theme.primary, 0.08))
        border.width: 1
        border.color: AppController.notificationTone === "error"
            ? theme.tint(theme.error, 0.28)
            : (AppController.notificationTone === "success"
                ? theme.tint(theme.success, 0.22)
                : theme.tint(theme.primary, 0.2))
        opacity: window.toastVisible ? 1 : 0
        visible: opacity > 0
        z: 20

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: AppController.notificationTone === "error"
                    ? theme.error
                    : (AppController.notificationTone === "success" ? theme.success : theme.primary)
            }

            Label {
                id: toastLabel
                Layout.fillWidth: true
                text: AppController.notificationMessage
                color: theme.textPrimary
                font.family: theme.fontUi
                font.pixelSize: theme.textBody
                elide: Text.ElideRight
            }
        }

        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        y: window.toastVisible ? 24 : 10
    }
}
