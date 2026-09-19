import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "shanjeev.screensaver-toggle"

  readonly property string flagPath: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/screensaver-off"

  // The flag file is what omarchy-launch-screensaver checks: present means the
  // screensaver is off, while the idle lock and screen-off keep running.
  property bool screensaverOff: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    id: flagFile
    path: root.flagPath
    watchChanges: true
    printErrors: false
    onLoaded: root.screensaverOff = true
    onLoadFailed: root.screensaverOff = false
    onFileChanged: reload()
  }

  // A watch cannot be placed on a file that does not exist yet, so poll to
  // notice the flag being created (e.g. by `omarchy toggle screensaver`).
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: flagFile.reload()
  }

  Process {
    id: toggleProcess
    command: ["omarchy-toggle", "screensaver-off"]
    onExited: flagFile.reload()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.screensaverOff ? "󰶐" : "󱄄"
    dimmed: root.screensaverOff
    tooltipText: root.screensaverOff ? "Screensaver off (screen still locks when idle)" : "Screensaver on"
    onPressed: function(b) {
      if (!toggleProcess.running) toggleProcess.running = true
    }
  }
}
