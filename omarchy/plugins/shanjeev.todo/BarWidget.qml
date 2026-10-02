import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "shanjeev.todo"

  implicitWidth: barSize
  implicitHeight: barSize

  Process {
    id: toggler
    command: ["omarchy-shell", "todo", "toggle"]
  }

  Text {
    id: icon
    anchors.centerIn: parent
    text: ""
    color: root.bar ? root.bar.foreground : Color.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body + 2
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: toggler.running = true
  }
}
