import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Todo.js" as TodoState

BarWidget {
  id: root
  moduleName: "shanjeev.todo"

  readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy-todo.json"

  property var todoItems: []
  readonly property int todoTotal: todoItems.length
  readonly property int todoPending: TodoState.remaining(todoItems)

  implicitWidth: row.implicitWidth + Style.space(8)
  implicitHeight: barSize

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.todoItems = TodoState.parse(text())
    onLoadFailed: root.todoItems = []
    onFileChanged: reload()
  }

  Process {
    id: toggler
    command: ["omarchy-shell", "todo", "toggle"]
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(4)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: (root.todoTotal > 0 && root.todoPending === 0) ? "󰄬" : "󰄱"
      color: root.bar ? root.bar.foreground : Color.foreground
      font.pixelSize: Style.font.body
    }

    Text {
      visible: root.todoTotal > 0
      anchors.verticalCenter: parent.verticalCenter
      text: root.todoPending + "/" + root.todoTotal
      color: root.bar ? root.bar.foreground : Color.foreground
      font.pixelSize: Style.font.body
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: toggler.running = true
  }
}
