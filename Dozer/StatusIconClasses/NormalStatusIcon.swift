import Cocoa
import Defaults

class NormalStatusIcon: HelperstatusIcon {
    override init() {
        super.init()
        type = .normal
    }

    override func statusIconClicked(_: AnyObject?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        if currentEvent.modifierFlags.contains(.option) &&
            !currentEvent.modifierFlags.contains(.control) &&
            !currentEvent.modifierFlags.contains(.command) {
            DozerIcons.shared.handleOptionClick()

            return
        }

        switch currentEvent.type {
        case .leftMouseDown:
            DozerIcons.shared.toggle()
        case .rightMouseDown:
            AppDelegate.shared.preferencesWindowController.show(preferencePane: .general)
        default:
            break
        }
    }
}
