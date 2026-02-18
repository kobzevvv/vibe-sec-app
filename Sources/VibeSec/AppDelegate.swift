import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Kill other instances of VibeSec (prevent duplicates in menu bar)
        let myPID = ProcessInfo.processInfo.processIdentifier
        for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == "com.vibesec.menubar" {
            if app.processIdentifier != myPID {
                app.terminate()
            }
        }

        controller = StatusBarController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller = nil
    }
}
