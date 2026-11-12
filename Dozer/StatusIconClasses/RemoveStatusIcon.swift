import Cocoa
import Defaults

class RemoveStatusIcon: HelperstatusIcon {
    override init() {
        super.init()
        type = .remove
        statusIcon.button?.setAccessibilityLabel("Dozer extra-hidden section divider")
        statusIcon.button?.toolTip = "Icons to the left stay hidden on normal clicks. Option-click a Dozer dot to reveal them."
    }

    override func statusIconClicked(_: AnyObject?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        switch NormalStatusIcon.clickAction(
            eventType: currentEvent.type,
            eventModifiers: currentEvent.modifierFlags,
            currentModifiers: NSEvent.modifierFlags
        ) {
        case .toggle:
            DozerIcons.shared.toggleRemove()
        case .optionClick:
            DozerIcons.shared.handleOptionClick()
        case .preferences:
            AppDelegate.shared.preferencesWindowController.show(preferencePane: .general)
        case .ignore:
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
