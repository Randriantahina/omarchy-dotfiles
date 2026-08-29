import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property string userName: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: "Enter your password to unlock"
  readonly property int cardWidth: 400
  readonly property int cardPadding: Style.space(28)
  readonly property int fieldWidth: cardWidth - cardPadding * 2
  readonly property int fieldHeight: 56
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  function timeOfDayGreeting() {
    var h = clock.now.getHours()
    if (h < 5) return "Good night"
    if (h < 12) return "Good morning"
    if (h < 18) return "Good afternoon"
    return "Good evening"
  }

  readonly property string avatarInitial: userName.length > 0 ? userName.charAt(0).toUpperCase() : "?"

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  QtObject {
    id: clock
    property date now: new Date()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.now = new Date()
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Column {
      anchors.centerIn: parent
      spacing: Style.spacing.xxl

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.spacing.sm

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(clock.now, "HH:mm")
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.displayLarge * 2
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(clock.now, "dddd, d MMMM")
          color: Util.alpha(Color.foreground, 0.7)
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
        }
      }

      BorderSurface {
        id: card
        width: root.cardWidth
        height: cardColumn.implicitHeight + root.cardPadding * 2
        radius: Style.cornerRadius
        color: Color.lock.background
        borderSpec: Border.surfaceSpec("lock", "border", Color.lock.border, 1, "border-alpha")

        Column {
          id: cardColumn
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: root.cardPadding
          width: root.fieldWidth
          spacing: Style.spacing.lg

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 64
            height: 64
            radius: 32
            color: Util.alpha(Color.accent, 0.18)
            border.color: Util.alpha(Color.accent, 0.45)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: root.avatarInitial
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.display
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeOfDayGreeting() + (root.userName.length > 0 ? ", " + root.userName : "")
            color: Color.lock.text
            font.family: Style.font.family
            font.pixelSize: Style.font.title
          }

          BorderSurface {
            id: inputField
            width: root.fieldWidth
            height: root.fieldHeight
            anchors.horizontalCenter: parent.horizontalCenter
            color: Util.alpha(Color.background, 0.35)
            borderSpec: root.inputBorderSpec
            radius: Style.cornerRadius
            clip: true

            TextInput {
              id: passwordInput
              anchors.fill: parent
              anchors.topMargin: inputField.borderTop
              // Reserve the fingerprint icon's width on both sides so the centered
              // dots stay symmetric and never slide under it as they grow.
              anchors.rightMargin: inputField.borderRight + 14 + root.fingerprintReserve
              anchors.bottomMargin: inputField.borderBottom
              anchors.leftMargin: inputField.borderLeft + 14 + root.fingerprintReserve
              verticalAlignment: TextInput.AlignVCenter
              horizontalAlignment: TextInput.AlignHCenter
              activeFocusOnPress: true
              clip: true
              enabled: root.inputEnabled && !root.authenticatingPassword
              readOnly: root.authenticatingPassword
              echoMode: TextInput.Password
              passwordCharacter: "●"
              passwordMaskDelay: 0
              color: Color.lock.text
              selectionColor: Color.lock.selection
              selectedTextColor: Color.lock.text
              font.family: Style.font.family
              font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
              font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
              cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
              cursorDelegate: Rectangle {
                width: 2
                color: Color.lock.text
                visible: passwordInput.cursorVisible
              }

              onTextChanged: {
                if (!root.syncingPasswordText) root.passwordTextEdited(text)
                if (text.length > 0) {
                  root.wakeRequested()
                }
                if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
              }

              onAccepted: {
                var submitted = root.passwordText
                root.passwordTextEdited("")
                if (submitted.length > 0) root.submitPassword(submitted)
              }

              Keys.onPressed: function(event) {
                root.wakeRequested()
                if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                  root.passwordTextEdited("")
                  event.accepted = true
                }
              }
            }

            Text {
              anchors.fill: passwordInput
              text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
              visible: passwordInput.text.length === 0
              color: root.authenticatingPassword ? Color.lock.text : (root.failureMessage.length > 0 ? Color.lock.textError : Color.lock.placeholder)
              font.family: Style.font.family
              font.pixelSize: Style.font.subtitle
              font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
            }

            // Fingerprint hint pinned inside the field's right edge when a sensor is
            // enrolled, so the user knows they can touch to unlock instead of typing.
            Text {
              id: fingerprintIcon
              objectName: "fingerprintIndicator"
              anchors.right: parent.right
              anchors.rightMargin: inputField.borderRight + 14
              anchors.verticalCenter: parent.verticalCenter
              visible: root.fingerprintConfigured
              text: "󰈷"
              color: Color.lock.placeholder
              font.family: Style.font.family
              font.pixelSize: Math.round(root.fieldFontSize * 1.1)
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }
        }
      }
    }
  }
}
