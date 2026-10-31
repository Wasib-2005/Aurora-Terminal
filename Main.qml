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
    property bool screenActive: true
    property bool animationsEnabled: true
    property bool authFailed: false
    property bool leaving: false
    property bool authenticating: false
    property bool glitching: false
    property int glitchStep: 0
    property real gx: 0
    property real gy: 0
    property real gflick: 1
    property real intro: 0
    property string idleFocusTarget: ""
    readonly property bool motionActive: screenActive && animationsEnabled
    readonly property bool compact: width < 900 || height < 680

    // Staggered entrance: returns eased 0..1 progress for a slice of the intro timeline
    function stage(start, span) {
        var t = (intro - start) / span
        t = Math.max(0, Math.min(1, t))
        return 1 - Math.pow(1 - t, 3)
    }

    // Typewriter reveal tied to the intro timeline
    function typeText(str, start, span) {
        return str.substring(0, Math.round(str.length * stage(start, span)))
    }

    function refreshClock() {
        var now = new Date()
        var hour = now.getHours()
        root.hourText = String(hour % 12 || 12)
        root.minuteText = Qt.formatTime(now, "mm")
        root.periodText = hour < 12 ? "AM" : "PM"
        root.dateText = Qt.formatDate(now, "dddd, d MMMM")
        // Sleep until the next minute boundary instead of polling every second
        clockTimer.interval = 60000 - now.getSeconds() * 1000 - now.getMilliseconds() + 30
    }

    function submitLogin() {
        if (usernameField.text.trim().length === 0) {
            message = "Username is required."
            usernameField.forceActiveFocus()
            return
        }

        message = ""
        authFailed = false
        authenticating = true
        sddm.login(usernameField.text, passwordField.text, Math.max(sessionBox.currentIndex, 0))
    }

    function focusInitialInput() {
        if (usernameField.text.trim().length > 0) {
            passwordField.forceActiveFocus()
        } else {
            usernameField.forceActiveFocus()
        }
    }

    function noteActivity() {
        if (screenActive)
            idleTimer.restart()
    }

    function wakeFromIdle() {
        if (screenActive) {
            idleTimer.restart()
            return
        }

        screenActive = true
        refreshClock()
        idleTimer.restart()
        Qt.callLater(function() {
            if (idleFocusTarget === "username") {
                usernameField.forceActiveFocus()
            } else if (idleFocusTarget === "password") {
                passwordField.forceActiveFocus()
            } else if (idleFocusTarget === "session") {
                sessionBox.forceActiveFocus()
            }
            idleFocusTarget = ""
        })
    }

    function enterIdleMode() {
        if (idleFocusTarget.length === 0) {
            rememberIdleFocusTarget()
        }
        screenActive = false
    }

    function rememberIdleFocusTarget() {
        if (passwordField.activeFocus) {
            idleFocusTarget = "password"
        } else if (usernameField.activeFocus) {
            idleFocusTarget = "username"
        } else if (sessionBox.activeFocus) {
            idleFocusTarget = "session"
        } else {
            idleFocusTarget = ""
        }
    }

    onAnimationsEnabledChanged: {
        if (!animationsEnabled && intro < 1) {
            introAnim.stop()
            intro = 1
        }
    }

    NumberAnimation {
        id: introAnim
        target: root
        property: "intro"
        from: 0
        to: 1
        duration: 1300
        easing.type: Easing.Linear
    }

    Timer {
        id: glitchTimer
        interval: 2500
        running: root.motionActive && !root.glitching
        repeat: true
        onTriggered: {
            root.glitchStep = 0
            root.glitching = true
        }
    }

    Timer {
        interval: 45
        running: root.glitching
        repeat: true
        onTriggered: {
            root.glitchStep++
            if (root.glitchStep >= 7 || !root.motionActive) {
                root.glitching = false
                root.gx = 0
                root.gy = 0
                root.gflick = 1
                glitchTimer.interval = 2200 + Math.random() * 4500
            } else {
                root.gx = (Math.random() - 0.5) * 16
                root.gy = (Math.random() - 0.5) * 4
                root.gflick = Math.random() > 0.55 ? 0.7 : 1
            }
        }
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: root.screenActive
        repeat: true
        onTriggered: root.refreshClock()
    }

    Timer {
        id: idleTimer
        interval: 30000
        running: true
        onTriggered: root.enterIdleMode()
    }

    HoverHandler {
        onPointChanged: root.noteActivity()
    }

    TapHandler {
        onPressedChanged: {
            if (pressed)
                root.noteActivity()
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
            root.authFailed = true
            root.authenticating = false
            passwordField.text = ""
            passwordField.forceActiveFocus()
            if (root.animationsEnabled)
                shakeAnim.restart()
        }
        function onLoginSucceeded() {
            root.message = ""
            root.authFailed = false
            root.authenticating = false
            root.leaving = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#090d0e"
    }

    Rectangle {
        id: backgroundPanel
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

        SequentialAnimation {
            loops: Animation.Infinite
            running: root.motionActive
            ParallelAnimation {
                NumberAnimation {
                    target: backgroundPanel
                    property: "x"
                    to: root.width * 0.24
                    duration: 9000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: backgroundPanel
                    property: "y"
                    to: root.height * 0.015
                    duration: 9000
                    easing.type: Easing.InOutSine
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: backgroundPanel
                    property: "x"
                    to: root.width * 0.21
                    duration: 9000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: backgroundPanel
                    property: "y"
                    to: root.height * 0.04
                    duration: 9000
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    Rectangle {
        id: auroraWash
        width: root.width * 0.4
        height: root.height * 0.78
        x: root.width * 0.12
        y: root.height * 0.1
        rotation: -18
        property real glowOpacity: 0.16
        opacity: glowOpacity * root.stage(0, 0.9)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1d4641" }
            GradientStop { position: 0.55; color: "#102a2b" }
            GradientStop { position: 1.0; color: "#00090d0e" }
        }

        SequentialAnimation {
            loops: Animation.Infinite
            running: root.motionActive
            NumberAnimation {
                target: auroraWash
                property: "x"
                to: root.width * 0.17
                duration: 24000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: auroraWash
                property: "x"
                to: root.width * 0.12
                duration: 24000
                easing.type: Easing.InOutSine
            }
        }

        SequentialAnimation {
            loops: Animation.Infinite
            running: root.motionActive
            NumberAnimation {
                target: auroraWash
                property: "glowOpacity"
                to: 0.24
                duration: 9000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: auroraWash
                property: "glowOpacity"
                to: 0.12
                duration: 9000
                easing.type: Easing.InOutSine
            }
        }
    }

    // Rising motes
    Repeater {
        model: root.animationsEnabled ? 16 : 0

        Rectangle {
            required property int index
            property real baseX: root.width * (((index * 53) % 97) / 97)
            property real life: 0
            width: index % 3 === 0 ? 3 : 2
            height: width
            color: index % 4 === 0 ? "#7cc7ff" : "#b6fa73"
            x: baseX + Math.sin(life * 6.28 + index) * 14
            y: root.height + 10 - life * (root.height + 20)
            opacity: Math.sin(Math.PI * life) * 0.35 * root.stage(0.4, 0.6)

            SequentialAnimation on life {
                loops: Animation.Infinite
                running: root.motionActive
                PauseAnimation { duration: index * 650 }
                NumberAnimation { from: 0; to: 1; duration: 12000 + (index % 5) * 3000 }
            }
        }
    }

    // Expanding rings behind the clock
    Repeater {
        model: (root.compact || !root.animationsEnabled) ? 0 : 2

        Rectangle {
            id: ring
            required property int index
            width: 560
            height: 560
            radius: 280
            x: Math.max(68, root.width * 0.105) + Math.min(root.width * 0.46, 680) / 2 - 280
            y: root.height / 2 - 295
            color: "transparent"
            border.width: 1
            border.color: "#2a5a52"
            opacity: 0
            scale: 0.3

            SequentialAnimation {
                loops: Animation.Infinite
                running: root.motionActive
                PauseAnimation { duration: 1500 + ring.index * 3600 }
                ParallelAnimation {
                    NumberAnimation { target: ring; property: "scale"; from: 0.3; to: 1; duration: 7200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring; property: "opacity"; from: 0.18; to: 0; duration: 7200; easing.type: Easing.OutQuad }
                }
                PauseAnimation { duration: 800 }
            }
        }
    }

    // Glitch tear slices
    Repeater {
        model: 3

        Rectangle {
            required property int index
            visible: root.glitching
            width: root.width * (0.4 + index * 0.2)
            height: 2 + index * 2
            x: root.gx * 6 + index * root.width * 0.15
            y: root.height * (0.18 + index * 0.27) + root.gy * 14
            color: index === 1 ? "#2fe0ff" : "#b6fa73"
            opacity: 0.1
        }
    }

    // Scan band
    Item {
        id: scanBand
        width: root.width
        height: 90
        y: -90
        visible: root.animationsEnabled

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00b6fa73" }
                GradientStop { position: 1.0; color: "#0eb6fa73" }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#22b6fa73"
        }

        SequentialAnimation on y {
            loops: Animation.Infinite
            running: root.motionActive
            PauseAnimation { duration: 3500 }
            NumberAnimation { from: -90; to: root.height; duration: 6500 }
        }
    }

    TextMetrics {
        id: statusMetrics
        text: "AWAITING CREDENTIALS"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 1
    }

    // Corner brackets around the login form
    Item {
        id: formFrame
        visible: !root.compact
        x: loginForm.x - 20 - root.gx * 0.8
        y: loginForm.y - 20
        width: loginForm.width + 40
        height: loginForm.height + 40
        property real pulse: 1
        property real len: 16 * root.stage(0.35, 0.5)
        property color tone: root.authFailed ? "#ff9f89" : "#3d5a4d"
        opacity: root.stage(0.35, 0.5) * pulse
        Behavior on tone { enabled: root.motionActive; ColorAnimation { duration: 160 } }

        SequentialAnimation on pulse {
            loops: Animation.Infinite
            running: root.authenticating && root.animationsEnabled
            NumberAnimation { to: 0.3; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
            onRunningChanged: if (!running) formFrame.pulse = 1
        }

        Rectangle { x: 0; y: 0; width: formFrame.len; height: 1; color: formFrame.tone }
        Rectangle { x: 0; y: 0; width: 1; height: formFrame.len; color: formFrame.tone }
        Rectangle { x: formFrame.width - formFrame.len; y: 0; width: formFrame.len; height: 1; color: formFrame.tone }
        Rectangle { x: formFrame.width - 1; y: 0; width: 1; height: formFrame.len; color: formFrame.tone }
        Rectangle { x: 0; y: formFrame.height - 1; width: formFrame.len; height: 1; color: formFrame.tone }
        Rectangle { x: 0; y: formFrame.height - formFrame.len; width: 1; height: formFrame.len; color: formFrame.tone }
        Rectangle { x: formFrame.width - formFrame.len; y: formFrame.height - 1; width: formFrame.len; height: 1; color: formFrame.tone }
        Rectangle { x: formFrame.width - 1; y: formFrame.height - formFrame.len; width: 1; height: formFrame.len; color: formFrame.tone }
    }

    Rectangle {
        width: 1
        height: root.height * root.stage(0.1, 0.7)
        x: root.width * 0.58
        color: "#10282b"
        opacity: root.width > 900 ? 0.75 : 0
    }

    Rectangle {
        width: root.width * 0.34 * root.stage(0.2, 0.7)
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
        opacity: root.stage(0, 0.4) * root.gflick
        transform: Translate { x: -root.gx }

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
            text: root.typeText("LOCAL SESSION  /  AUTH GATE", 0.1, 0.5)
            color: "#8b9e99"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            Rectangle {
                id: systemReadyDot
                width: 7
                height: 7
                radius: 1
                color: "#b6fa73"
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: readyRing
                    anchors.centerIn: parent
                    width: 7
                    height: 7
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: "#b6fa73"
                    opacity: 0

                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: root.motionActive
                        ParallelAnimation {
                            NumberAnimation { target: readyRing; property: "scale"; from: 1; to: 4; duration: 2400; easing.type: Easing.OutCubic }
                            NumberAnimation { target: readyRing; property: "opacity"; from: 0.7; to: 0; duration: 2400; easing.type: Easing.OutQuad }
                        }
                        PauseAnimation { duration: 900 }
                    }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.motionActive
                    NumberAnimation { to: 0.45; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                }
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
        opacity: root.stage(0.05, 0.5) * root.gflick
        transform: [
            Translate { y: (1 - root.stage(0.05, 0.5)) * 22 },
            Translate { x: root.gx; y: root.gy }
        ]
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
            font.letterSpacing: root.compact ? 1.3 : 1.3 + (1 - root.stage(0.05, 0.6)) * 3
        }

        Repeater {
            model: 2

            Text {
                required property int index
                visible: root.glitching
                anchors.left: root.compact ? undefined : parent.left
                anchors.horizontalCenter: root.compact ? parent.horizontalCenter : undefined
                anchors.top: clockDate.bottom
                anchors.topMargin: root.compact ? 7 : 18
                text: root.hourText + ":" + root.minuteText
                color: index === 0 ? "#ff2f5f" : "#2fe0ff"
                opacity: 0.45
                font.family: "monospace"
                font.pixelSize: root.compact ? 52 : Math.min(164, root.width * 0.105)
                font.weight: Font.Light
                transform: Translate { x: (index === 0 ? -1 : 1) * (4 + Math.abs(root.gx)) }
            }
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
                font.family: "monospace"
                font.pixelSize: root.compact ? 52 : Math.min(164, root.width * 0.105)
                font.weight: Font.Light

                SequentialAnimation on opacity {
                    id: colonPulse
                    loops: Animation.Infinite
                    running: root.motionActive
                    NumberAnimation { to: 0.35; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                    onRunningChanged: if (!running) clockColon.opacity = 1
                }
            }

            Text {
                id: minuteDigits
                text: root.minuteText
                transform: Translate { id: minuteSlide }
                onTextChanged: if (root.motionActive) minuteAnim.restart()
                ParallelAnimation {
                    id: minuteAnim
                    NumberAnimation { target: minuteSlide; property: "y"; from: 16; to: 0; duration: 380; easing.type: Easing.OutCubic }
                    NumberAnimation { target: minuteDigits; property: "opacity"; from: 0.15; to: 1; duration: 380; easing.type: Easing.OutQuad }
                }
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
            text: root.typeText("LOCAL SESSION  /  READY FOR INPUT", 0.4, 0.5)
            color: "#758680"
            font.family: "monospace"
            font.pixelSize: 11
            font.letterSpacing: 1.2
            opacity: root.stage(0.3, 0.4)
        }
    }

    Column {
        id: loginForm
        opacity: root.stage(0.18, 0.5) * root.gflick
        transform: [
            Translate { y: (1 - root.stage(0.18, 0.5)) * 18 },
            Translate { id: formShake },
            Translate { x: root.gx * 0.5 }
        ]
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

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: formShake; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: formShake; property: "x"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: formShake; property: "x"; to: -6; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: formShake; property: "x"; to: 3; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: formShake; property: "x"; to: 0; duration: 50; easing.type: Easing.InQuad }
        }

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
            transform: Translate { id: glitchT }

            SequentialAnimation {
                loops: Animation.Infinite
                running: root.motionActive
                PauseAnimation { duration: 6500 }
                NumberAnimation { target: glitchT; property: "x"; to: 4; duration: 35 }
                NumberAnimation { target: glitchT; property: "x"; to: -3; duration: 35 }
                NumberAnimation { target: glitchT; property: "x"; to: 2; duration: 35 }
                NumberAnimation { target: glitchT; property: "x"; to: 0; duration: 35 }
                onRunningChanged: if (!running) glitchT.x = 0
            }

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
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: root.noteActivity()
            cursorDelegate: Item {
                objectName: "usernameCursorDash"
                width: 9
                height: usernameField.font.pixelSize
                visible: usernameField.activeFocus

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 2
                    color: "#b6fa73"
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.motionActive
                    NumberAnimation { to: 0.15; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
            onAccepted: passwordField.forceActiveFocus()
            background: Rectangle {
                color: "transparent"
                border.width: 0
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#32423d"

            Rectangle {
                height: parent.height
                width: usernameField.activeFocus ? parent.width : 0
                color: "#b6fa73"
                Behavior on width { enabled: root.motionActive; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }
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
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: {
                root.authFailed = false
                root.noteActivity()
            }
            cursorDelegate: Item {
                objectName: "passwordCursorDash"
                width: 9
                height: passwordField.font.pixelSize
                visible: passwordField.activeFocus

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 2
                    color: "#b6fa73"
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.motionActive
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
            color: root.authFailed ? "#5a2f2a" : "#32423d"
            Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 160 } }

            Rectangle {
                height: parent.height
                width: (passwordField.activeFocus || root.authFailed) ? parent.width : 0
                color: root.authFailed ? "#ff9f89" : "#b6fa73"
                Behavior on width { enabled: root.motionActive; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 160 } }
            }
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
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: root.noteActivity()
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
                    rotation: sessionBox.popup.visible ? 180 : 0
                    Behavior on rotation { enabled: root.motionActive; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }
                popup: Popup {
                    y: sessionBox.height + 4
                    width: sessionBox.width
                    padding: 4
                    enter: Transition {
                        enabled: root.motionActive
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                    exit: Transition {
                        enabled: root.motionActive
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 100
                            easing.type: Easing.InCubic
                        }
                    }
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
                        leftPadding: parent.highlighted ? 4 : 0
                        Behavior on leftPadding { enabled: root.motionActive; NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
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
            opacity: text.length > 0 ? 1 : 0
            text: root.message
            color: "#ff9f89"
            font.family: "monospace"
            font.pixelSize: 11
            elide: Text.ElideRight
            Behavior on opacity { enabled: root.motionActive; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Button {
            id: signInButton
            width: parent.width
            height: root.compact ? 42 : 50
            scale: down ? 0.985 : 1
            text: root.authenticating ? "AUTHENTICATING" : "ENTER SESSION"
            onClicked: root.submitLogin()
            Behavior on scale { enabled: root.motionActive; NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            contentItem: Row {
                spacing: signInButton.hovered ? 16 : 12
                anchors.centerIn: parent
                Behavior on spacing { enabled: root.motionActive; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
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
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 120 } }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 2
                    clip: true
                    visible: root.authenticating

                    Rectangle {
                        width: 90
                        height: 2
                        color: "#b6fa73"

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            running: root.authenticating && root.animationsEnabled
                            NumberAnimation { from: -90; to: signInButton.width; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                }
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
    }

    Row {
        id: statusRow
        opacity: root.stage(0.45, 0.45) * root.gflick
        transform: [
            Translate { y: (1 - root.stage(0.45, 0.45)) * 10 },
            Translate { x: root.gx * 0.6 }
        ]
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

            SequentialAnimation on opacity {
                id: caretBlink
                loops: Animation.Infinite
                running: root.motionActive
                NumberAnimation { to: 0.2; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) statusCaret.opacity = 1
            }
        }

        Text {
            text: root.authenticating ? "VERIFYING..." : root.typeText("AWAITING CREDENTIALS", 0.5, 0.5)
            width: statusMetrics.advanceWidth
            color: "#758680"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 1
            anchors.verticalCenter: parent.verticalCenter
        }

        Button {
            id: animationButton
            text: root.animationsEnabled ? "STOP ANIMATION" : "START ANIMATION"
            width: root.compact ? 116 : 128
            height: root.compact ? 28 : 30
            hoverEnabled: true
            onClicked: root.animationsEnabled = !root.animationsEnabled
            contentItem: Text {
                text: animationButton.text
                color: animationButton.hovered || animationButton.down ? "#ffffff" : "#b6fa73"
                font.family: "monospace"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: animationButton.down ? "#263b2b" : animationButton.hovered ? "#1b2d22" : "transparent"
                border.color: animationButton.hovered ? "#ffffff" : "#52604e"
                border.width: 1
                radius: 2
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 120 } }
                Behavior on border.color { enabled: root.motionActive; ColorAnimation { duration: 120 } }
            }
        }
    }

    Row {
        id: powerRow
        opacity: root.stage(0.55, 0.45) * root.gflick
        transform: [
            Translate { y: (1 - root.stage(0.55, 0.45)) * 10 },
            Translate { x: root.gx * -0.6 }
        ]
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
            Behavior on scale { enabled: root.motionActive; NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            contentItem: Text {
                text: sleepButton.text
                color: !sleepButton.enabled && !sleepPointer.hovered ? "#84917f" : sleepPointer.hovered || sleepButton.down ? "#ffffff" : "#bff58f"
                font.family: "monospace"
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
            }
            background: Rectangle {
                radius: 3
                color: !sleepButton.enabled && !sleepPointer.hovered ? "#151b17" : sleepButton.down ? "#87b85e" : sleepPointer.hovered ? "#bff58f" : "transparent"
                border.color: !sleepButton.enabled && !sleepPointer.hovered ? "#52604e" : sleepPointer.hovered || sleepButton.down ? "#ffffff" : "#bff58f"
                border.width: 1
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
                Behavior on border.color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
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
            Behavior on scale { enabled: root.motionActive; NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            contentItem: Text {
                text: restartButton.text
                color: !restartButton.enabled && !restartPointer.hovered ? "#78858a" : restartPointer.hovered || restartButton.down ? "#ffffff" : "#7cc7ff"
                font.family: "monospace"
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
            }
            background: Rectangle {
                radius: 3
                color: !restartButton.enabled && !restartPointer.hovered ? "#151a1b" : restartButton.down ? "#5b9ac6" : restartPointer.hovered ? "#7cc7ff" : "transparent"
                border.color: !restartButton.enabled && !restartPointer.hovered ? "#4d5b5a" : restartPointer.hovered || restartButton.down ? "#ffffff" : "#7cc7ff"
                border.width: 1
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
                Behavior on border.color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
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
            Behavior on scale { enabled: root.motionActive; NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            contentItem: Text {
                text: powerOffButton.text
                color: !powerOffButton.enabled && !powerOffPointer.hovered ? "#8f7773" : powerOffPointer.hovered || powerOffButton.down ? "#ffffff" : "#ff8a80"
                font.family: "monospace"
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
            }
            background: Rectangle {
                radius: 3
                color: !powerOffButton.enabled && !powerOffPointer.hovered ? "#1c1716" : powerOffButton.down ? "#bd5c56" : powerOffPointer.hovered ? "#ff8a80" : "transparent"
                border.color: !powerOffButton.enabled && !powerOffPointer.hovered ? "#614843" : powerOffPointer.hovered || powerOffButton.down ? "#ffffff" : "#ff8a80"
                border.width: 1
                Behavior on color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
                Behavior on border.color { enabled: root.motionActive; ColorAnimation { duration: 100 } }
            }
        }
    }

    // Fade to black after successful login
    Rectangle {
        anchors.fill: parent
        z: 90
        color: "#000000"
        opacity: root.leaving ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { enabled: root.animationsEnabled; NumberAnimation { duration: 380; easing.type: Easing.InOutQuad } }
    }

    // Idle blackout: slow fade in, quick fade out on wake
    Item {
        anchors.fill: parent
        z: 100
        visible: !root.screenActive || blackout.opacity > 0
        focus: !root.screenActive

        Rectangle {
            id: blackout
            anchors.fill: parent
            color: "#000000"
            opacity: root.screenActive ? 0 : 1
            Behavior on opacity {
                enabled: root.animationsEnabled
                NumberAnimation {
                    duration: root.screenActive ? 220 : 1200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !root.screenActive
            onPressed: root.wakeFromIdle()
        }

        Keys.onPressed: function(event) {
            root.wakeFromIdle()
            event.accepted = true
        }
    }

    Component.onCompleted: {
        refreshClock()
        focusInitialInput()
        if (animationsEnabled)
            introAnim.start()
        else
            intro = 1
    }
}
