import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Todo.js" as TodoState

// Ephemeral daily todo. State lives in $XDG_RUNTIME_DIR (a tmpfs), so it
// survives a shell restart but is wiped when the machine shuts down.
// The bar widget opens/closes the panel through the "todo" IPC target.
Item {
  id: root

  readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy-todo.json"

  property var items: []
  property bool open: false

  function save(newItems) {
    root.items = newItems
    stateFile.setText(TodoState.serialize(newItems))
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.items = TodoState.parse(text())
    onLoadFailed: root.items = []
    onFileChanged: reload()
  }

  IpcHandler {
    target: "todo"

    function toggle(): string { root.open = !root.open; return "ok" }
    function open(): string { root.open = true; return "ok" }
    function close(): string { root.open = false; return "ok" }
  }

  PanelWindow {
    id: panel
    visible: root.open
    anchors { top: true; right: true }
    margins { top: Style.space(40); right: Style.gapsOut }
    implicitWidth: Style.space(380)
    implicitHeight: Style.space(500)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "omarchy-todo"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
      windows: [panel]
      active: root.open
      onCleared: root.open = false
    }

    onVisibleChanged: if (visible) input.forceActiveFocus()

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: Color.popups.background
      border.color: Color.popups.border
      border.width: 1

      FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.open = false

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(16)
          spacing: Style.space(10)

          RowLayout {
            Layout.fillWidth: true

            Text {
              text: "Todo du jour"
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.body + 4
              font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
              text: (root.items.length - TodoState.remaining(root.items)) + "/" + root.items.length + " faites"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
          }

          Text {
            text: Qt.formatDate(new Date(), "dddd d MMMM")
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }

          TextField {
            id: input
            Layout.fillWidth: true
            placeholderText: "Ajouter une tâche…"
            onAccepted: {
              root.save(TodoState.add(root.items, text))
              text = ""
            }
          }

          ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Style.space(4)
            model: root.items

            delegate: Rectangle {
              id: row
              required property var modelData
              width: list.width
              height: Style.space(34)
              radius: Style.spacing.labelGap
              color: hover.hovered ? Style.hoverFill : "transparent"

              HoverHandler { id: hover }

              Rectangle {
                id: box
                anchors.left: parent.left
                anchors.leftMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(18)
                height: width
                radius: Style.spacing.labelGap
                color: row.modelData.done ? Color.accent : "transparent"
                border.color: Color.accent
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  visible: row.modelData.done
                  text: "✓"
                  color: Color.background
                  font.pixelSize: Style.font.body
                }
              }

              Text {
                anchors.left: box.right
                anchors.leftMargin: Style.space(10)
                anchors.right: del.left
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.text
                elide: Text.ElideRight
                color: row.modelData.done ? Color.muted : Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.strikeout: row.modelData.done
              }

              MouseArea {
                anchors.fill: parent
                anchors.rightMargin: Style.space(34)
                cursorShape: Qt.PointingHandCursor
                onClicked: root.save(TodoState.toggle(root.items, row.modelData.id))
              }

              Text {
                id: del
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                visible: hover.hovered
                text: "×"
                color: Color.urgent
                font.pixelSize: Style.font.body + 4

                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -Style.space(6)
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.save(TodoState.remove(root.items, row.modelData.id))
                }
              }
            }
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.items.length === 0
            text: "Rien pour l'instant ✨"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }

          Button {
            Layout.fillWidth: true
            text: "Effacer les terminées"
            onClicked: root.save(TodoState.clearDone(root.items))
          }
        }
      }
    }
  }
}
