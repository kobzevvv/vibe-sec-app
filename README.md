# vibe-sec — macOS Menubar App

Native macOS status bar app for [vibe-sec](https://github.com/kobzevvv/vibe-sec) — security monitoring for AI coding agents.

**→ Main project (scanner, hook guard, full docs): [github.com/kobzevvv/vibe-sec](https://github.com/kobzevvv/vibe-sec)**

## What it does

Sits in your menu bar and shows the security status of your machine at a glance:

- **`VB`** — always visible, clean and minimal
- **Dot badge** — appears when new findings are detected, clears when you open the menu
- **Scan Now** — runs the vibe-sec log scanner in the background
- **Open Report** — opens the interactive HTML report at `localhost:7777`
- **Copy commands** — click any terminal command to copy it (no scary AppleScript permissions)

## Requirements

- macOS 13+
- [vibe-sec](https://github.com/kobzevvv/vibe-sec) installed (`npx vibe-sec setup`)

## Build & Run

```bash
git clone https://github.com/kobzevvv/vibe-sec-app
cd vibe-sec-app
swift build -c release
open VibeSec.app
```

## Privacy

On first scan, the app explains exactly what it reads:
- Claude Code session logs (`~/.claude/`)
- Shell history (`~/.zsh_history`)
- Documents and Downloads (for leaked API keys and `.env` files)

**Nothing leaves your machine.** The scanner runs entirely locally.
