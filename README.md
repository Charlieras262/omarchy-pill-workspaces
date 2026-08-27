# Pill Workspaces

An [Omarchy](https://omarchy.org) bar-widget plugin: a drop-in replacement
for the stock `omarchy.workspaces` widget where the active workspace renders
as a rounded, filled pill instead of just losing its dim/idle opacity. The
number's color automatically picks whichever theme color contrasts best
against the pill, so it stays legible across light and dark themes alike.

## Install

```bash
omarchy plugin add https://github.com/Charlieras262/omarchy-pill-workspaces.git --enable
```

This clones the plugin into `~/.config/omarchy/plugins/` and switches the
bar's workspaces slot to it. `omarchy plugin update` later pulls new
versions the same way any git-managed plugin does.

## Configure

All settings are optional and set per-instance in
`~/.config/omarchy/shell.json`, on the widget's own layout entry:

```json
{
  "id": "charlieras262.pill-workspaces",
  "maxWorkspaces": 6,
  "indicatorColor": "urgent",
  "indicatorRadius": 8,
  "indicatorXInset": 4,
  "indicatorYInset": 4,
  "indicatorBold": false
}
```

| Key | Type | Default | Description |
|---|---|---|---|
| `maxWorkspaces` | number | `5` | How many workspace slots to always show. A workspace beyond this count still shows up once something is open on it. |
| `indicatorColor` | `"foreground"` \| `"accent"` \| `"urgent"` \| `"muted"` | `"accent"` | Which theme color fills the active workspace's pill. |
| `indicatorRadius` | number (px) | `6` | Corner radius of the pill. |
| `indicatorXInset` | number (px) | `2` | Horizontal gap (left + right) between the pill and the edge of its cell. |
| `indicatorYInset` | number (px) | `6` | Vertical gap (top + bottom) between the pill and the edge of the bar, so it reads as a pill rather than a full-height block. |
| `indicatorBold` | boolean | `true` | Bold the active workspace's number. Set `false` for a normal weight. |

> Upgrading from 1.0.1 or earlier: `indicatorInset` was split into
> `indicatorXInset`/`indicatorYInset`. If you had set `indicatorInset`,
> replace it with `indicatorYInset` (same meaning, same default) and add
> `indicatorXInset` only if you also want a horizontal gap.

The file hot-reloads — no restart needed after editing it.

## Remove

```bash
omarchy plugin remove charlieras262.pill-workspaces
```

This removes the plugin's files and switches the bar's workspaces slot
back to the stock `omarchy.workspaces` widget.

## Dependencies

None beyond what a stock Omarchy install already ships — this is plain
QML built on Omarchy's own `qs.Commons`/`qs.Ui` modules and the
Quickshell Hyprland integration, no external packages or services.

## Why not just theme the stock widget?

Omarchy's built-in `omarchy.workspaces` widget only changes opacity for the
focused workspace; it doesn't have a way to render a filled shape or pick a
contrasting text color. This plugin is a clone of that widget with those two
behaviors added, kept close enough to the original that clone-and-diff
against a future stock version stays easy.

## License

MIT — see [LICENSE](LICENSE).
