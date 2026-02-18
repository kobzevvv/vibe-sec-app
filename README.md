# vibe-sec — macOS Menubar App

Native macOS status bar app for [vibe-sec](https://github.com/kobzevvv/vibe-sec) — security monitoring for AI coding agents.

**→ Main project (scanner, hook guard, full docs): [github.com/kobzevvv/vibe-sec](https://github.com/kobzevvv/vibe-sec)**

## What it does

Sits in your menu bar and shows the security status of your machine at a glance:

- **`VB`** — always visible, clean and minimal
- **Dot badge** — appears when new findings are detected, clears when you open the menu
- **Scan Now** — runs the vibe-sec log scanner in the background with a checkbox picker (choose what to scan)
- **Open Report** — opens the interactive HTML report at `localhost:7777`
- **Copy commands** — click any terminal command to copy it (no scary AppleScript permissions)

## Install

**Option A — Download (easiest)**

1. Download `VibeSec-x.x.x.zip` from [Releases](https://github.com/kobzevvv/vibe-sec-app/releases/latest)
2. Unzip → drag `VibeSec.app` to `/Applications`
3. If macOS blocks it: **System Settings → Privacy & Security → Open Anyway**

**Option B — Homebrew**

```bash
brew tap kobzevvv/tap
brew install --cask vibe-sec-app
```

**Option C — Build from source**

```bash
git clone https://github.com/kobzevvv/vibe-sec-app
cd vibe-sec-app
swift build -c release
open .build/release/VibeSec
```

## Requirements

- macOS 13+
- [vibe-sec](https://github.com/kobzevvv/vibe-sec) installed: `npx vibe-sec setup`

## Privacy

On first scan, the app shows exactly what it will read — with checkboxes to skip anything you don't want:

- Claude Code session logs (`~/.claude/`)
- Shell history (`~/.zsh_history`)
- Git repos in `~/Documents/GitHub/` (looks for `.env` files)
- Downloads folder (API key files, service account JSON)
- clawdbot config (`~/.clawdbot/`)
- Safari/Chrome history (visited cloud & financial services)
- System checks (open ports, firewall, screen lock)

**Nothing leaves your machine.** Full source: [github.com/kobzevvv/vibe-sec](https://github.com/kobzevvv/vibe-sec)
