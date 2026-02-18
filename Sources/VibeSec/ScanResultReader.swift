import Foundation

struct ScanResult {
    let score: Int?
    let date: String?
    let isInstalled: Bool
}

class ScanResultReader {

    // Cached regexes (compiled once)
    private static let findingsCommentRegex = try! NSRegularExpression(
        pattern: #"<!--\s*findings:\s*(\d+)\s*-->"#
    )
    private static let issueCountRegex = try! NSRegularExpression(
        pattern: #"(\d+)\s+issue"#,
        options: .caseInsensitive
    )
    private static let findingCountRegex = try! NSRegularExpression(
        pattern: #"(\d+)\s+finding"#,
        options: .caseInsensitive
    )
    private static let verboseRegex = try! NSRegularExpression(
        pattern: #"\*\*(\d+)\s+critical[^*]*?(\d+)\s+high-severity"#,
        options: .caseInsensitive
    )

    static func read() -> ScanResult {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/vibe-sec")

        // Check if vibe-sec is installed by looking for the hook script
        let hookScript = configDir.appendingPathComponent("scripts/hook.mjs")
        guard FileManager.default.fileExists(atPath: hookScript.path) else {
            return ScanResult(score: nil, date: nil, isInstalled: false)
        }

        // Find all report files
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(
                at: configDir,
                includingPropertiesForKeys: nil
            )
        } catch {
            return ScanResult(score: nil, date: nil, isInstalled: true)
        }

        let reportFiles = files
            .filter {
                $0.lastPathComponent.hasPrefix("vibe-sec-log-report-") &&
                $0.pathExtension == "md"
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard let latest = reportFiles.last else {
            return ScanResult(score: nil, date: nil, isInstalled: true)
        }

        // Parse content
        let content: String
        do {
            content = try String(contentsOf: latest, encoding: .utf8)
        } catch {
            return ScanResult(score: nil, date: nil, isInstalled: true)
        }

        let score = parseScore(from: content)

        // Extract date from filename: vibe-sec-log-report-2024-01-15.md
        let dateStr = latest.lastPathComponent
            .replacingOccurrences(of: "vibe-sec-log-report-", with: "")
            .replacingOccurrences(of: ".md", with: "")

        return ScanResult(score: score, date: dateStr.isEmpty ? nil : dateStr, isInstalled: true)
    }

    private static func parseScore(from content: String) -> Int? {
        let range = NSRange(content.startIndex..., in: content)

        // 1. Primary: machine-readable HTML comment <!-- findings: N -->
        if let match = findingsCommentRegex.firstMatch(in: content, range: range),
           let captureRange = Range(match.range(at: 1), in: content),
           let value = Int(content[captureRange]) {
            return value
        }

        // 2. "No static issues found" means 0
        if content.range(of: "no static issues found", options: [.caseInsensitive]) != nil {
            return 0
        }

        // 3. Fallback: verbose verdict note "N critical and M high-severity"
        if let match = verboseRegex.firstMatch(in: content, range: range),
           let r1 = Range(match.range(at: 1), in: content),
           let r2 = Range(match.range(at: 2), in: content),
           let critical = Int(content[r1]),
           let high = Int(content[r2]) {
            return critical + high
        }

        // 4. Last fallback: any "N issue" or "N finding" pattern
        for regex in [issueCountRegex, findingCountRegex] {
            if let match = regex.firstMatch(in: content, range: range),
               let captureRange = Range(match.range(at: 1), in: content),
               let value = Int(content[captureRange]) {
                return value
            }
        }

        return nil
    }
}
