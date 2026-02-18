import AppKit

class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let statusMenuItem   = NSMenuItem()   // "Not installed" / "● 3 findings"
    private let actionMenuItem   = NSMenuItem()   // "→ Open Terminal to install" / "→ Run first scan"
    private let hookMenuItem     = NSMenuItem()   // "Setup Hook Guard" / "✓ Hook Guard active"
    private let scanMenuItem     = NSMenuItem(title: "Scan Now", action: #selector(scanNow), keyEquivalent: "s")
    private var timer: Timer?
    private var isScanning = false
    private var reportServerProcess: Process?
    private var lastResult: ScanResult?
    private var acknowledgedScore: Int? = nil  // score user has already seen

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        menu = NSMenu()
        super.init()

        setupMenu()
        refresh()

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
        reportServerProcess?.terminate()
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        // Title
        let titleItem = NSMenuItem(title: "vibe-sec", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        titleItem.attributedTitle = NSAttributedString(
            string: "vibe-sec",
            attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]
        )
        menu.addItem(titleItem)

        // Status line (disabled, shows current state)
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        // Action hint (enabled, contextual — changes based on state)
        actionMenuItem.isHidden = true
        actionMenuItem.target = self
        menu.addItem(actionMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Hook guard status / install
        hookMenuItem.target = self
        menu.addItem(hookMenuItem)

        menu.addItem(NSMenuItem.separator())

        let reportItem = NSMenuItem(title: "Open Report", action: #selector(openReport), keyEquivalent: "o")
        reportItem.target = self
        menu.addItem(reportItem)

        scanMenuItem.target = self
        menu.addItem(scanMenuItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit vibe-sec", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        menu.delegate = self
    }

    // MARK: - Refresh

    func refresh() {
        let result = ScanResultReader.read()
        updateIcon(result: result)
        updateStatusArea(result: result)
        updateHookStatus()
    }

    // MARK: - Icon

    private func updateIcon(result: ScanResult) {
        guard let button = statusItem.button else { return }
        lastResult = result

        // VB is always labelColor — no red/yellow/green on the letters
        let str = NSMutableAttributedString(
            string: "VB",
            attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: NSFont.systemFont(ofSize: 11.5, weight: .thin),
                .kern: NSNumber(value: 1.5),
            ]
        )

        // Dot: show when there are findings the user hasn't seen yet
        let hasUnread = result.isInstalled
            && result.score != nil
            && result.score != acknowledgedScore
        if hasUnread {
            str.append(NSAttributedString(
                string: "\u{2022}",  // bullet •
                attributes: [
                    .foregroundColor: NSColor.labelColor.withAlphaComponent(0.7),
                    .font: NSFont.systemFont(ofSize: 5.5, weight: .bold),
                    .baselineOffset: NSNumber(value: 5.5),
                ]
            ))
        }

        button.image = nil
        button.attributedTitle = str
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // Dot burns out when user opens the menu
        acknowledgedScore = lastResult?.score
        if let result = lastResult {
            updateIcon(result: result)
        }
    }

    // MARK: - Status Area

    private func updateStatusArea(result: ScanResult) {
        if !result.isInstalled {
            // State: not installed
            statusMenuItem.attributedTitle = nil
            statusMenuItem.title = "Not installed"

            actionMenuItem.isHidden = false
            actionMenuItem.action = #selector(copyInstallCommand)
            actionMenuItem.attributedTitle = makeActionString("npx vibe-sec")
            return
        }

        if result.score == nil {
            // State: installed, no scan yet
            statusMenuItem.attributedTitle = nil
            statusMenuItem.title = "No scan results yet"

            actionMenuItem.isHidden = false
            actionMenuItem.action = #selector(copyScanCommand)
            actionMenuItem.attributedTitle = makeActionString("npx vibe-sec scan")
            return
        }

        // State: installed, has results
        actionMenuItem.isHidden = true

        let score = result.score!
        let dotColor: NSColor = score == 0 ? .systemGreen : score <= 5 ? .systemYellow : .systemRed
        let label: String = score == 0 ? "Clean — no issues" : "\(score) finding\(score == 1 ? "" : "s")"

        let full = NSMutableAttributedString()
        full.append(NSAttributedString(string: "● ", attributes: [.foregroundColor: dotColor]))
        full.append(NSAttributedString(string: label))
        if let dateStr = result.date, !dateStr.isEmpty {
            full.append(NSAttributedString(
                string: "  \(dateStr)",
                attributes: [.foregroundColor: NSColor.secondaryLabelColor]
            ))
        }
        statusMenuItem.attributedTitle = full
    }

    // Styled action item: "$ command" in monospace with copy icon hint
    private func makeActionString(_ command: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        // Prompt character
        result.append(NSAttributedString(
            string: "$ ",
            attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular),
            ]
        ))
        // Command
        result.append(NSAttributedString(
            string: command,
            attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .medium),
            ]
        ))
        // Copy hint — same size as command text
        result.append(NSAttributedString(
            string: "  ⎘",
            attributes: [
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .medium),
            ]
        ))
        return result
    }

    // Shows "✓ Copied!" briefly, then restores the original label
    private func flashCopied(command: String) {
        let copied = NSMutableAttributedString()
        copied.append(NSAttributedString(
            string: "✓ Copied — paste in Terminal",
            attributes: [
                .foregroundColor: NSColor.systemGreen,
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            ]
        ))
        actionMenuItem.attributedTitle = copied

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.actionMenuItem.attributedTitle = self?.makeActionString(command)
        }
    }

    // MARK: - Hook Guard Status

    private func isHookInstalled() -> Bool {
        let settingsFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        guard let data = try? Data(contentsOf: settingsFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any],
              let preToolUse = hooks["PreToolUse"] as? [[String: Any]] else {
            return false
        }
        return preToolUse.contains { entry in
            guard let hookList = entry["hooks"] as? [[String: Any]] else { return false }
            return hookList.contains { h in
                (h["command"] as? String)?.contains("hook.mjs") == true
            }
        }
    }

    private func updateHookStatus() {
        if isHookInstalled() {
            hookMenuItem.attributedTitle = makeHookActiveString()
            hookMenuItem.action = nil
            hookMenuItem.isEnabled = false
        } else {
            hookMenuItem.action = #selector(copyHookCommand)
            hookMenuItem.attributedTitle = makeActionString("npx vibe-sec setup")
            hookMenuItem.isEnabled = true
        }
    }

    private func makeHookActiveString() -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "✓ ",
            attributes: [
                .foregroundColor: NSColor.systemGreen,
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .medium),
            ]
        ))
        result.append(NSAttributedString(
            string: "Hook Guard active",
            attributes: [
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize + 1),
            ]
        ))
        result.append(NSAttributedString(
            string: "  — runs on every command, <5ms, survives restarts",
            attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize - 1),
            ]
        ))
        return result
    }

    // MARK: - Copy Actions (no AppleScript, no scary permissions)

    @objc private func copyInstallCommand() {
        copyCommand("npx vibe-sec")
    }

    @objc private func copyScanCommand() {
        copyCommand("npx vibe-sec scan")
    }

    @objc private func copyHookCommand() {
        copyCommand("npx vibe-sec setup")
    }

    private func copyCommand(_ command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        flashCopied(command: command)
    }

    // MARK: - Report

    @objc private func openReport() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/vibe-sec")

        // Find latest HTML report (generated by scan-logs.mjs)
        if let files = try? FileManager.default.contentsOfDirectory(at: configDir, includingPropertiesForKeys: nil) {
            let htmlReports = files
                .filter { $0.lastPathComponent.hasPrefix("vibe-sec-log-report-") && $0.pathExtension == "html" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if let latest = htmlReports.last {
                NSWorkspace.shared.open(latest)
                return
            }
        }

        // Fallback: launch interactive server if no HTML report exists
        let scriptPath = configDir.appendingPathComponent("scripts/serve-report.mjs")
        let reportURL = URL(string: "http://localhost:7777")!

        if reportServerProcess == nil || !reportServerProcess!.isRunning {
            if FileManager.default.fileExists(atPath: scriptPath.path) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                task.arguments = ["node", scriptPath.path]
                task.currentDirectoryURL = configDir
                task.standardOutput = FileHandle.nullDevice
                task.standardError = FileHandle.nullDevice
                try? task.run()
                reportServerProcess = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    NSWorkspace.shared.open(reportURL)
                }
                return
            }
        }
        NSWorkspace.shared.open(reportURL)
    }

    // MARK: - Scan

    @objc private func scanNow() {
        guard !isScanning else { return }
        guard let options = ScanPermissionPanel.present() else { return }

        isScanning = true
        scanMenuItem.title = "Scanning..."
        scanMenuItem.isEnabled = false

        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/vibe-sec")
        let scriptPath = configDir.appendingPathComponent("scripts/scan-logs.mjs")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = ["node", scriptPath.path, "--static-only", "--source", "app"] + options.skipArgs
            task.currentDirectoryURL = configDir
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            do { try task.run(); task.waitUntilExit() } catch {}

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.isScanning = false
                self.scanMenuItem.title = "Scan Now"
                self.scanMenuItem.isEnabled = true
                self.refresh()
            }
        }
    }

    // MARK: - Quit

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
