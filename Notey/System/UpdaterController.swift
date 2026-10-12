import AppKit
import Sparkle

@MainActor
final class UpdaterController: NSObject {

    private let controller: SPUStandardUpdaterController?

    override init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        let isConfigured = !key.isEmpty && !key.hasPrefix("REPLACE")
        if Bundle.main.bundleURL.pathExtension == "app" && isConfigured {
            controller = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            controller = nil
        }
        super.init()
    }

    var isAvailable: Bool {
        controller != nil
    }

    func checkForUpdates() {
        guard let controller else {
            let alert = NSAlert()
            alert.messageText = "Updates are not configured"
            alert.informativeText = "This build has no Sparkle public key, so it cannot check for updates."
            alert.runModal()
            return
        }
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }
}
