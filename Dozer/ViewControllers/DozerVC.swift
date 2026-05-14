import Cocoa
import Sparkle
import Preferences

final class Dozer: NSViewController, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.dozer
    let preferencePaneTitle: String = "Dozer"
    let toolbarItemIcon = NSImage(named: "AppIcon")!

    override var nibName: NSNib.Name? { "Dozer" }

    @IBOutlet private var versionLabel: NSTextField!
    @IBOutlet private var checkForUpdates: NSButton!
    @IBOutlet private var quit: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let releaseVersionNumber = AppInfo.releaseVersionNumber,
            let buildVersionNumber = AppInfo.buildVersionNumber {
            versionLabel.stringValue = "\(releaseVersionNumber) (\(buildVersionNumber))"
        }

        let updater = AppDelegate.shared.sparkleUpdaterController
        checkForUpdates.target = updater
        checkForUpdates.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))

        quit.action = #selector(NSApp.terminate(_:))
    }
}
