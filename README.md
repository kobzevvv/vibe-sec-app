# vibe-sec menubar app

A macOS menubar companion for [vibe-sec](https://github.com/vovayatsyuk/vibe-sec) — the security scanner for AI coding agents.

## What it does

Shows a colored shield icon in the macOS menu bar reflecting your latest vibe-sec scan result:

- Green shield — no issues (score = 0)
- Yellow shield — 1–5 issues
- Red shield — 6+ issues
- Grey shield — no scan results yet
- Grey shield/slash — vibe-sec not installed

Clicking the icon shows a menu with the finding count, last scan date, and quick actions.

## Requirements

- macOS 13.0 (Ventura) or later
- [vibe-sec](https://github.com/vovayatsyuk/vibe-sec) installed (`npx vibe-sec`)
- Node.js (for running scan scripts)
- Xcode Command Line Tools (`xcode-select --install`)

## Run for development

```bash
swift run
```

The menubar icon will appear immediately. Press Ctrl+C in the terminal to quit, or use "Quit vibe-sec" from the menu.

## Build a release binary

```bash
swift build -c release
# Binary is at: .build/release/VibeSec
```

## Create a proper .app bundle (for permanent use)

A proper `.app` bundle is required for `LSUIElement` (no Dock icon) to take effect system-wide. Here is how to create one manually after building:

```bash
# 1. Build release binary
swift build -c release

# 2. Create bundle structure
mkdir -p VibeSec.app/Contents/MacOS
mkdir -p VibeSec.app/Contents/Resources

# 3. Copy binary and Info.plist
cp .build/release/VibeSec VibeSec.app/Contents/MacOS/VibeSec
cp Resources/Info.plist VibeSec.app/Contents/

# 4. Launch
open VibeSec.app
```

To have it launch at login, add `VibeSec.app` to System Settings > General > Login Items.

## How it reads data

The app scans `~/.config/vibe-sec/vibe-sec-log-report-*.md` and picks the most recent file. It parses the issue count using these patterns:

- `Score: N`
- `N issue(s)`
- `N finding(s)`

It checks for vibe-sec installation by looking for `~/.config/vibe-sec/scripts/hook.mjs`.

## Menu actions

| Action | Description |
|--------|-------------|
| Open Report | Starts `serve-report.mjs` if present, then opens http://localhost:7777 |
| Scan Now | Runs `scan-logs.mjs --static-only` in the background, refreshes on completion |
| Quit vibe-sec | Exits the app |

The icon and status line auto-refresh every 60 seconds.
