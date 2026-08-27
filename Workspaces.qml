import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Drop-in replacement for the stock omarchy.workspaces bar widget. The
// active workspace renders as a rounded, filled pill instead of just
// losing its dim/idle opacity, and its number picks whichever theme color
// contrasts best against the fill so it stays legible across themes.
//
// Configurable per-instance via shell.json (all optional):
//   maxWorkspaces   - how many workspace slots to always show. Default 5.
//   indicatorColor  - "foreground" | "accent" | "urgent" | "muted". Default "foreground".
//   indicatorRadius - corner radius of the pill, in px. Default 6.
//   indicatorXInset - horizontal inset (left+right) of the pill, in px. Default 0.
//   indicatorYInset - vertical inset (top+bottom) of the pill, in px. Default 6.
BarWidget {
  id: root
  moduleName: "charlieras262.pill-workspaces"

  readonly property int maxWorkspaces: Number(setting("maxWorkspaces", 5))
  readonly property string indicatorColorName: String(setting("indicatorColor", "foreground"))
  readonly property real indicatorRadius: Number(setting("indicatorRadius", 6))
  readonly property real indicatorXInset: Number(setting("indicatorXInset", 0))
  readonly property real indicatorYInset: Number(setting("indicatorYInset", 6))

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  // Always shows slots 1..maxWorkspaces, plus any higher workspace that
  // already has something open on it (so nothing already in use disappears
  // just because it's past the configured count).
  function workspaceIds() {
    var ids = []
    for (var n = 1; n <= root.maxWorkspaces; n++) ids.push(n)

    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function colorByName(name) {
    if (name === "accent") return Color.accent
    if (name === "urgent") return Color.urgent
    if (name === "muted") return Color.muted
    return Color.foreground
  }

  // Relative luminance (0-1). Used to pick whichever theme text color
  // actually contrasts against the active indicator, since some themes pair
  // a light indicator with a light foreground (or vice versa).
  function luminance(c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
  }

  readonly property color activeIndicatorColor: colorByName(root.indicatorColorName)
  readonly property color activeTextColor: Math.abs(luminance(activeIndicatorColor) - luminance(Color.background))
    > Math.abs(luminance(activeIndicatorColor) - luminance(Color.foreground))
    ? Color.background
    : Color.foreground

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: cell
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        // indicatorXInset must widen the cell, not just shrink the pill
        // inside a fixed-width one -- otherwise a large inset crushes the
        // pill (and the number inside it) down to a sliver instead of just
        // adding breathing room around it, on the horizontal layout's fairly
        // tight per-cell width.
        implicitWidth: root.vertical ? root.barSize : Style.space(20) + root.indicatorXInset * 2
        implicitHeight: root.barSize

        Rectangle {
          anchors.fill: parent
          anchors.leftMargin: root.indicatorXInset
          anchors.rightMargin: root.indicatorXInset
          anchors.topMargin: root.indicatorYInset
          anchors.bottomMargin: root.indicatorYInset
          color: cell.focused ? root.activeIndicatorColor : "transparent"
          radius: root.indicatorRadius
        }

        WidgetButton {
          anchors.fill: parent
          bar: root.bar
          text: cell.modelData === 10 ? "0" : String(cell.modelData)
          foreground: cell.focused ? root.activeTextColor : Color.foreground
          useActiveColor: false
          opacity: cell.occupied || cell.focused ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          onPressed: function() { root.focusWorkspace(cell.modelData) }
        }
      }
    }
  }
}
