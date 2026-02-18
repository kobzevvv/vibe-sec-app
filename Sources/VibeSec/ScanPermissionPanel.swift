import AppKit

struct ScanOptions {
    var claudeCode   = true
    var shellHistory = true
    var gitRepos     = true
    var downloads    = true
    var clawdbot     = true
    var browser      = true
    var system       = true

    /// CLI flags to pass to scan-logs.mjs
    var skipArgs: [String] {
        var args: [String] = []
        if !claudeCode   { args.append("--skip-claude") }
        if !shellHistory { args.append("--skip-shell") }
        if !gitRepos     { args.append("--skip-git") }
        if !downloads    { args.append("--skip-downloads") }
        if !clawdbot     { args.append("--skip-clawdbot") }
        if !browser      { args.append("--skip-browser") }
        if !system       { args.append("--skip-system") }
        return args
    }

    static func fromDefaults() -> ScanOptions {
        var opts = ScanOptions()
        let d = UserDefaults.standard
        func load(_ key: String, into value: inout Bool) {
            if d.object(forKey: key) != nil { value = d.bool(forKey: key) }
        }
        load("scanOpt_claudeCode",   into: &opts.claudeCode)
        load("scanOpt_shellHistory", into: &opts.shellHistory)
        load("scanOpt_gitRepos",     into: &opts.gitRepos)
        load("scanOpt_downloads",    into: &opts.downloads)
        load("scanOpt_clawdbot",     into: &opts.clawdbot)
        load("scanOpt_browser",      into: &opts.browser)
        load("scanOpt_system",       into: &opts.system)
        return opts
    }

    func saveToDefaults() {
        let d = UserDefaults.standard
        d.set(claudeCode,   forKey: "scanOpt_claudeCode")
        d.set(shellHistory, forKey: "scanOpt_shellHistory")
        d.set(gitRepos,     forKey: "scanOpt_gitRepos")
        d.set(downloads,    forKey: "scanOpt_downloads")
        d.set(clawdbot,     forKey: "scanOpt_clawdbot")
        d.set(browser,      forKey: "scanOpt_browser")
        d.set(system,       forKey: "scanOpt_system")
    }
}

enum ScanPermissionPanel {

    // Returns nil if user cancelled, ScanOptions if confirmed.
    static func present() -> ScanOptions? {
        var opts = ScanOptions.fromDefaults()
        let firstTime = !UserDefaults.standard.bool(forKey: "scanPermissionsExplained")

        let alert = NSAlert()
        alert.messageText = "What vibe-sec will scan"
        alert.informativeText = firstTime
            ? "vibe-sec reads the following on your Mac only.\nUncheck anything you want to skip. Nothing leaves your machine."
            : "Choose what to include in this scan.\nNothing leaves your machine."

        // Build checkbox list
        let items: [(String, WritableKeyPath<ScanOptions, Bool>)] = [
            ("Claude Code — session logs, settings, MCP config", \.claudeCode),
            ("Shell — command history (~/.zsh_history)",          \.shellHistory),
            ("Git repos — .env files in ~/Documents/GitHub/",     \.gitRepos),
            ("Downloads — API key files, service account JSON",    \.downloads),
            ("clawdbot — Telegram bot token (~/.clawdbot/)",       \.clawdbot),
            ("Safari/Chrome — visited cloud & financial services", \.browser),
            ("System — open ports, firewall, screen lock",         \.system),
        ]

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .left
        stack.spacing = 6

        var buttons: [(NSButton, WritableKeyPath<ScanOptions, Bool>)] = []
        for (label, keyPath) in items {
            let btn = NSButton(checkboxWithTitle: label, target: nil, action: nil)
            btn.state = opts[keyPath: keyPath] ? .on : .off
            btn.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize + 1)
            stack.addArrangedSubview(btn)
            buttons.append((btn, keyPath))
        }

        let fitting = stack.fittingSize
        stack.frame = NSRect(x: 0, y: 0, width: max(fitting.width, 380), height: fitting.height)
        alert.accessoryView = stack

        alert.addButton(withTitle: "Scan Now")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return nil }

        // Read back checkbox states
        for (btn, keyPath) in buttons {
            opts[keyPath: keyPath] = btn.state == .on
        }
        opts.saveToDefaults()

        if firstTime {
            UserDefaults.standard.set(true, forKey: "scanPermissionsExplained")
        }

        return opts
    }
}
