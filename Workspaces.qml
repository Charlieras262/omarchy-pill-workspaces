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
//   maxWorkspaces   - how many workspace slots to always show. Default 5,
//                     clamped to 1-36 (see clampMaxWorkspaces()).
//   indicatorColor  - "foreground" | "accent" | "urgent" | "muted". Default "foreground".
//   indicatorRadius - corner radius of the pill, in px. Default 6, clamped
//                     to 0-200 (see clampPixels()).
//   indicatorXInset - extra padding (left+right) around the pill, in px.
//                     Default 2, clamped to 0-200.
//   indicatorYInset - shrinks the pill's side length from the bar's height,
//                     in px on each edge. Default 6, clamped to 0-200. The
//                     pill is always square: its side is
//                     barSize - indicatorYInset * 2, and indicatorXInset
//                     only adds padding around that square rather than
//                     resizing it. A single bar-widget can't grow the
//                     bar's own thickness (every other widget shares it)
//                     the way it can grow its own cell's width, so making
//                     the pill bigger than the default means lowering
//                     indicatorYInset or raising the bar's own height
//                     (shell.toml's [bar] size-horizontal).
//   indicatorBold   - bold the active workspace's number. Default true.
BarWidget {
  id: root
  moduleName: "charlieras262.pill-workspaces"

  // Clamped: shell.json is user-editable, and an oversized value here would
  // build an equally oversized workspaceIds() array and Repeater on the
  // shared shell UI thread -- a large enough number can freeze the whole
  // shell, not just this widget. 36 comfortably covers any real workspace
  // count while keeping a bad value cheap to render.
  function clampMaxWorkspaces(value) {
    var n = Math.floor(Number(value))
    if (!isFinite(n)) return 5
    return Math.max(1, Math.min(36, n))
  }
  readonly property int maxWorkspaces: clampMaxWorkspaces(setting("maxWorkspaces", 5))
  readonly property string indicatorColorName: String(setting("indicatorColor", "foreground"))

  // Clamped for the same reason as maxWorkspaces: these are user-editable
  // pixel values that feed straight into this cell's own geometry (and,
  // through pillSize, everything derived from it). A large indicatorXInset
  // builds an arbitrarily wide cell, and a large negative indicatorYInset
  // makes pillSize (barSize - indicatorYInset * 2) arbitrarily large --
  // either can make the shell allocate and render an oversized surface on
  // the shared UI thread. 200px comfortably covers any real layout.
  function clampPixels(value, fallback) {
    var n = Number(value)
    if (!isFinite(n)) return fallback
    return Math.max(0, Math.min(200, n))
  }
  readonly property real indicatorRadius: clampPixels(setting("indicatorRadius", 6), 6)
  readonly property real indicatorXInset: clampPixels(setting("indicatorXInset", 2), 2)
  readonly property real indicatorYInset: clampPixels(setting("indicatorYInset", 6), 6)
  readonly property bool indicatorBold: setting("indicatorBold", true) !== false
  // The pill is always square, sized off the bar's own (fixed, shared)
  // thickness rather than the per-cell width, which is free to grow.
  readonly property real pillSize: Math.max(0, barSize - indicatorYInset * 2)

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

        // indicatorXInset widens the cell around the (fixed-size, square)
        // pill instead of shrinking it -- otherwise a large inset crushes
        // the pill down to a sliver instead of just adding breathing room.
        // The perpendicular dimension can't grow the same way: it's the
        // bar's own shared thickness, not this cell's own footprint.
        implicitWidth: root.vertical ? root.barSize : Math.max(Style.space(20), root.pillSize) + root.indicatorXInset * 2
        implicitHeight: root.barSize

        Rectangle {
          anchors.centerIn: parent
          width: root.pillSize
          height: root.pillSize
          color: cell.focused ? root.activeIndicatorColor : "transparent"
          radius: root.indicatorRadius
        }

        WidgetButton {
          id: workspaceButton
          anchors.fill: parent
          bar: root.bar
          text: cell.modelData === 10 ? "0" : String(cell.modelData)
          foreground: cell.focused ? root.activeTextColor : Color.foreground
          useActiveColor: false
          opacity: cell.occupied || cell.focused ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          // WidgetButton has no bold passthrough, so its own label is hidden
          // and the number is drawn here instead, matching its font/color/
          // opacity but adding font.bold for the focused workspace.
          labelVisible: false
          onPressed: function() { root.focusWorkspace(cell.modelData) }
        }

        Text {
          anchors.centerIn: parent
          text: workspaceButton.text
          color: workspaceButton.foreground
          opacity: workspaceButton.opacity
          font.family: workspaceButton.fontFamily
          font.pixelSize: workspaceButton.fontSize
          font.bold: root.indicatorBold && cell.focused
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
