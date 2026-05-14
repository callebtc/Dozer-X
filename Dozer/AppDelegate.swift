import Cocoa
import Sparkle
import Defaults
import Preferences
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_: Notification) {
        KeyboardShortcuts.onKeyUp(for: .toggleMenuItems) {
            DozerIcons.shared.toggle()
        }

        _ = DozerIcons.shared

        DozerIcons.shared.hideAtLaunch()

        _ = DozerIcons.toggleDockIcon(showIcon: false)
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        DozerIcons.shared.showAll()
        return true
    }

    lazy var preferences: [PreferencePane] = [
        Dozer(),
        General()
    ]

    lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: preferences,
        style: .toolbarItems,
        animated: true,
        hidesToolbarForSingleItem: true
    )

    var sparkleUpdaterController: SPUStandardUpdaterController {
        updaterController
    }
}
