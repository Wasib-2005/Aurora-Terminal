import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    width: 1600
    height: 900
    property string message: ""
    property string hourText: ""
    property string minuteText: ""
    property string periodText: ""
    property string dateText: Qt.formatDate(new Date(), "dddd, d MMMM")
    readonly property bool compact: width < 900 || height < 680

    function refreshClock() {
        var now = new Date()
        var hour = now.getHours()
        root.hourText = String(hour % 12 || 12)
        root.minuteText = Qt.formatTime(now, "mm")
        root.periodText = hour < 12 ? "AM" : "PM"
        root.dateText = Qt.formatDate(now, "dddd, d MMMM")
    }

    function submitLogin() {
        if (usernameField.text.trim().length === 0) {
            message = "Username is required."
            usernameField.forceActiveFocus()
            return
        }

        message = ""
        sddm.login(usernameField.text, passwordField.text, Math.max(sessionBox.currentIndex, 0))
    }

    function focusInitialInput() {
        if (usernameField.text.trim().length > 0) {
            passwordField.forceActiveFocus()
        } else {
            usernameField.forceActiveFocus()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.refreshClock()
            statusCaret.opacity = statusCaret.opacity > 0.5 ? 0.25 : 1.0
            clockColon.opacity = clockColon.opacity > 0.5 ? 0.4 : 1.0
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: false
        onTriggered: root.focusInitialInput()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = "Authentication failed. Check your password and try again."
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.message = ""
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#090d0e"
    }

    Rectangle {
        width: root.width * 0.56
        height: root.height * 0.92
        x: root.width * 0.21
        y: root.height * 0.04
        rotation: -18
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#14252b" }
            GradientStop { position: 0.48; color: "#0e191e" }
            GradientStop { position: 1.0; color: "#00090d0e" }
        }
    }

    Rectangle {
        width: 1
        height: root.height
        x: root.width * 0.58
        color: "#10282b"
        opacity: root.width > 900 ? 0.75 : 0
    }

    Rectangle {
        width: root.width * 0.34
        height: 1
        x: root.width * 0.58
        y: root.height * 0.22
        color: "#10282b"
        opacity: root.width > 900 ? 0.75 : 0
    }

    Item {
        id: topBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.compact ? 24 : 52
        anchors.rightMargin: root.compact ? 24 : 52
        anchors.topMargin: root.compact ? 22 : 34
        height: 26

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "A / S"
            color: "#b6fa73"
            font.family: "monospace"
            font.pixelSize: 15
            font.weight: Font.Bold
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.verticalCenter: parent.verticalCenter
            text: "LOCAL SESSION  /  AUTH GATE"
            color: "#8b9e99"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            Rectangle {
                width: 7
                height: 7
                radius: 1
                color: "#b6fa73"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "SYSTEM READY"
                color: "#b6fa73"
                font.family: "monospace"
                font.pixelSize: 11
            }
        }
    }

    Item {
        id: clockPanel
        opacity: 0
        anchors.left: root.compact ? undefined : parent.left
        anchors.leftMargin: root.compact ? 0 : Math.max(68, root.width * 0.105)
        anchors.horizontalCenter: root.compact ? parent.horizontalCenter : undefined
        anchors.top: root.compact ? parent.top : undefined
        anchors.topMargin: root.compact ? 62 : 0
        anchors.verticalCenter: root.compact ? undefined : parent.verticalCenter
        anchors.verticalCenterOffset: -15
        width: root.compact ? root.width - 40 : Math.min(root.width * 0.46, 680)
        height: root.compact ? 86 : 270

        Text {
            id: clockDate
            anchors.left: root.compact ? undefined : parent.left
            anchors.horizontalCenter: root.compact ? parent.horizontalCenter : undefined
            anchors.top: parent.top
            text: root.dateText
            color: "#91a49e"
            font.family: "monospace"
            font.pixelSize: root.compact ? 11 : 14
            font.letterSpacing: 1.3
        }

        Row {
            id: clockRow
            anchors.left: root.compact ? undefined : parent.left
            anchors.horizontalCenter: root.compact ? parent.horizontalCenter : undefined
            anchors.top: clockDate.bottom
            anchors.topMargin: root.compact ? 7 : 18
            spacing: root.compact ? 1 : 3

            Text {
                text: root.hourText
                color: "#e5ece8"
                font.family: "monospace"
                font.pixelSize: root.compact ? 52 : Math.min(164, root.width * 0.105)
                font.weight: Font.Light
            }

            Text {
                id: clockColon
                text: ":"
                color: "#b6fa73"
                opacity: 1
                font.family: "monospace"
                font.pixelSize: root.compact ? 52 : Math.min(164, root.width * 0.105)
                font.weight: Font.Light
            }

            Text {
                text: root.minuteText
                color: "#e5ece8"
                font.family: "monospace"
                font.pixelSize: root.compact ? 52 : Math.min(164, root.width * 0.105)
                font.weight: Font.Light
            }

            Text {
                text: root.periodText
                color: "#b6fa73"
                font.family: "monospace"
                font.pixelSize: root.compact ? 13 : 18
                font.weight: Font.Medium
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.compact ? 9 : 25
                leftPadding: 8
            }
        }

        Text {
            visible: !root.compact
            anchors.left: parent.left
            anchors.top: clockRow.bottom
            anchors.topMargin: 18
            text: "LOCAL SESSION  /  READY FOR INPUT"
            color: "#758680"
            font.family: "monospace"
            font.pixelSize: 11
            font.letterSpacing: 1.2
        }

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 600
            easing.type: Easing.OutCubic
            running: true
        }
    }

    Column {
        id: loginForm
        opacity: 0
        anchors.left: root.width > 900 ? undefined : parent.left
        anchors.leftMargin: root.width > 900 ? 0 : 28
        anchors.right: root.width > 900 ? parent.right : undefined
        anchors.rightMargin: root.width > 900 ? Math.max(72, root.width * 0.12) : 0
        anchors.top: root.compact ? parent.top : undefined
        anchors.topMargin: root.compact ? 150 : 0
        anchors.verticalCenter: root.compact ? undefined : parent.verticalCenter
        anchors.verticalCenterOffset: 30
        width: Math.min(root.width > 900 ? 430 : root.width - 56, 430)
        spacing: root.compact ? 6 : 14

        Row {
            spacing: 9
            Text {
                text: "01"
                color: "#b6fa73"
                font.family: "monospace"
                font.pixelSize: 12
            }
            Text {
                text: "/  AUTHENTICATE"
                color: "#91a49e"
                font.family: "monospace"
                font.pixelSize: 12
                font.letterSpacing: 1.2
            }
        }

        Row {
            spacing: 0
            Text {
                text: "login"
                color: "#e5ece8"
                font.family: "monospace"
                font.pixelSize: 29
                font.weight: Font.Medium
            }
            Text {
                text: "();"
                color: "#b6fa73"
                font.family: "monospace"
                font.pixelSize: 29
                font.weight: Font.Medium
            }
        }

        Text {
            text: "IDENTITY"
            color: "#91a49e"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 1.5
            topPadding: 5
        }

        TextField {
            id: usernameField
            width: parent.width
            height: root.compact ? 36 : 44
            placeholderText: "username"
            color: "#e5ece8"
            placeholderTextColor: "#647670"
            font.family: "monospace"
            font.pixelSize: 16
            leftPadding: 0
            rightPadding: 8
            selectByMouse: true
            text: userModel.lastUser
            onAccepted: passwordField.forceActiveFocus()
            background: Rectangle {
                color: "transparent"
                border.width: 0
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: usernameField.activeFocus ? "#b6fa73" : "#32423d"
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            text: "PASSWORD"
            color: "#91a49e"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 1.5
            topPadding: 5
        }

        TextField {
            id: passwordField
            width: parent.width
            height: root.compact ? 36 : 44
            placeholderText: "••••••••••••"
            color: "#e5ece8"
            placeholderTextColor: "#647670"
            font.family: "monospace"
            font.pixelSize: 16
            leftPadding: 0
            rightPadding: 8
            echoMode: TextInput.Password
            selectByMouse: true
            cursorDelegate: Rectangle {
                objectName: "passwordCursorDash"
                width: 9
                height: 2
                color: "#b6fa73"
                visible: passwordField.activeFocus

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
            background: Rectangle {
                color: "transparent"
                border.width: 0
            }
            onAccepted: root.submitLogin()
        }

        Rectangle {
            width: parent.width
            height: 1
            color: passwordField.activeFocus ? "#b6fa73" : "#32423d"
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Row {
            width: parent.width
            spacing: 12
            Text {
                text: "DESKTOP"
                color: "#91a49e"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 1.2
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
                id: sessionBox
                width: parent.width - 82
                height: root.compact ? 32 : 38
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.family: "monospace"
                font.pixelSize: 12
                leftPadding: 0
                rightPadding: 28
                contentItem: Text {
                    text: sessionBox.displayText || "Default session"
                    color: "#c5d0ca"
                    font: sessionBox.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                indicator: Text {
                    text: "v"
                    color: "#b6fa73"
                    font.family: "monospace"
                    font.pixelSize: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }
                popup: Popup {
                    y: sessionBox.height + 4
                    width: sessionBox.width
                    padding: 4
                    background: Rectangle {
                        color: "#111a1b"
                        border.color: "#3b5149"
                        border.width: 1
                    }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: Math.min(contentHeight, 240)
                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                        currentIndex: sessionBox.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }
                }
                delegate: ItemDelegate {
                    width: sessionBox.width - 8
                    text: model.name
                    highlighted: sessionBox.highlightedIndex === index
                    contentItem: Text {
                        text: ">  " + parent.text
                        color: parent.highlighted ? "#b6fa73" : "#c5d0ca"
                        font: sessionBox.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        color: parent.highlighted ? "#1e302a" : "transparent"
                    }
                }
            }
        }

        Text {
            id: feedback
            width: parent.width
            height: 18
            text: root.message
            color: "#ff9f89"
            font.family: "monospace"
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Button {
            id: signInButton
            width: parent.width
            height: root.compact ? 42 : 50
            scale: down ? 0.985 : 1
            text: "ENTER SESSION"
            onClicked: root.submitLogin()
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            contentItem: Row {
                spacing: 12
                anchors.centerIn: parent
                Text {
                    text: ">"
                    color: "#b6fa73"
                    font.family: "monospace"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
                Text {
                    text: signInButton.text
                    color: "#b6fa73"
                    font.family: "monospace"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    font.letterSpacing: 1.4
                }
            }
            background: Rectangle {
                color: signInButton.down ? "#263b2b" : signInButton.hovered ? "#1b2d22" : "transparent"
                border.color: "#b6fa73"
                border.width: signInButton.activeFocus ? 2 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        Row {
            spacing: 6
            Text {
                text: "↵"
                color: "#b6fa73"
                font.family: "monospace"
                font.pixelSize: 11
            }
            Text {
                text: "press enter to continue"
                color: "#758680"
                font.family: "monospace"
                font.pixelSize: 10
            }
        }

        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 450
            easing.type: Easing.OutCubic
            running: true
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.compact ? 24 : 52
        anchors.bottomMargin: root.compact ? 20 : 32
        spacing: 9

        Rectangle {
            id: statusCaret
            width: 7
            height: 13
            color: "#b6fa73"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "AWAITING CREDENTIALS"
            color: "#758680"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.compact ? 16 : 40
        anchors.bottomMargin: root.compact ? 12 : 24
        spacing: 4

        Text {
            text: "POWER"
            color: "#758680"
            font.family: "monospace"
            font.pixelSize: 9
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
            rightPadding: 4
        }

        Button {
            id: sleepButton
            text: "SLEEP"
            width: root.compact ? 64 : 78
            height: root.compact ? 30 : 34
            scale: down ? 0.96 : 1
            hoverEnabled: true
            enabled: sddm.canSuspend
            onClicked: sddm.suspend()
            HoverHandler {
                id: sleepPointer
            }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            contentItem: Text {
                text: sleepButton.text
                color: !sleepButton.enabled && !sleepPointer.hovered ? "#84917f" : sleepPointer.hovered || sleepButton.down ? "#ffffff" : "#bff58f"
                font.family: "monospace"
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            background: Rectangle {
                radius: 3
                color: !sleepButton.enabled && !sleepPointer.hovered ? "#151b17" : sleepButton.down ? "#87b85e" : sleepPointer.hovered ? "#bff58f" : "transparent"
                border.color: !sleepButton.enabled && !sleepPointer.hovered ? "#52604e" : sleepPointer.hovered || sleepButton.down ? "#ffffff" : "#bff58f"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
            }
        }

        Button {
            id: restartButton
            text: "RESTART"
            width: root.compact ? 74 : 88
            height: root.compact ? 30 : 34
            scale: down ? 0.96 : 1
            hoverEnabled: true
            enabled: sddm.canReboot
            onClicked: sddm.reboot()
            HoverHandler {
                id: restartPointer
            }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            contentItem: Text {
                text: restartButton.text
                color: !restartButton.enabled && !restartPointer.hovered ? "#78858a" : restartPointer.hovered || restartButton.down ? "#ffffff" : "#7cc7ff"
                font.family: "monospace"
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            background: Rectangle {
                radius: 3
                color: !restartButton.enabled && !restartPointer.hovered ? "#151a1b" : restartButton.down ? "#5b9ac6" : restartPointer.hovered ? "#7cc7ff" : "transparent"
                border.color: !restartButton.enabled && !restartPointer.hovered ? "#4d5b5a" : restartPointer.hovered || restartButton.down ? "#ffffff" : "#7cc7ff"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
            }
        }

        Button {
            id: powerOffButton
            text: "POWER OFF"
            width: root.compact ? 88 : 108
            height: root.compact ? 30 : 34
            scale: down ? 0.96 : 1
            hoverEnabled: true
            enabled: sddm.canPowerOff
            onClicked: sddm.powerOff()
            HoverHandler {
                id: powerOffPointer
            }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            contentItem: Text {
                text: powerOffButton.text
                color: !powerOffButton.enabled && !powerOffPointer.hovered ? "#8f7773" : powerOffPointer.hovered || powerOffButton.down ? "#ffffff" : "#ff8a80"
                font.family: "monospace"
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
            background: Rectangle {
                radius: 3
                color: !powerOffButton.enabled && !powerOffPointer.hovered ? "#1c1716" : powerOffButton.down ? "#bd5c56" : powerOffPointer.hovered ? "#ff8a80" : "transparent"
                border.color: !powerOffButton.enabled && !powerOffPointer.hovered ? "#614843" : powerOffPointer.hovered || powerOffButton.down ? "#ffffff" : "#ff8a80"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
            }
        }
    }

    Component.onCompleted: {
        refreshClock()
        focusInitialInput()
    }
}
