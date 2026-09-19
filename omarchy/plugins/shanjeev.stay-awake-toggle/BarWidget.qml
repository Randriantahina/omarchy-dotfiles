import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "shanjeev.stay-awake-toggle"

  readonly property string flagPath: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake"

  // Same flag as `omarchy toggle idle`: present means the idle service does
  // nothing (no screensaver, no lock, no screen-off).
  property bool stayAwake: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    id: flagFile
    path: root.flagPath
    watchChanges: true
    printErrors: false
    onLoaded: root.stayAwake = true
    onLoadFailed: root.stayAwake = false
    onFileChanged: reload()
  }

  // A watch cannot be placed on a file that does not exist yet, so poll to
  // notice the flag being created (e.g. by `omarchy toggle idle`).
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: flagFile.reload()
  }

  Process {
    id: toggleProcess
    command: ["omarchy-toggle-idle", "toggle"]
    onExited: flagFile.reload()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰅶"
    dimmed: !root.stayAwake
    tooltipText: root.stayAwake ? "Stay awake on (no lock, no sleep)" : "Stay awake off"
    onPressed: function(b) {
      if (!toggleProcess.running) toggleProcess.running = true
    }
  }
}
