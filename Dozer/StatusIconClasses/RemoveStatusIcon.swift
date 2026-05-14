import Cocoa
import Defaults

class RemoveStatusIcon: HelperstatusIcon {
    override init() {
        super.init()
        type = .remove
    }

    override func statusIconClicked(_: AnyObject?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        switch currentEvent.type {
        case .leftMouseDown:
            DozerIcons.shared.toggleRemove()
        case .rightMouseDown:
            AppDelegate.shared.preferencesWindowController.show(preferencePane: .general)
        default:
            break
        }
    }

    override func setIcon() {
        guard let statusIconButton = statusIcon.button else {
            fatalError("helper status item button failed")
        }
        statusIconButton.image = Icons().removeStatusIcon
        statusIconButton.image!.isTemplate = true
    }
}
