import Cocoa

class NormalStatusIcon: HelperstatusIcon {
    override init() {
        super.init()
        type = .normal
    }

    override func statusIconClicked(_: AnyObject?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        if Self.isOptionClick(eventModifiers: currentEvent.modifierFlags, currentModifiers: NSEvent.modifierFlags) {
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

    static func isOptionClick(eventModifiers: NSEvent.ModifierFlags, currentModifiers: NSEvent.ModifierFlags) -> Bool {
        let modifiers = eventModifiers.union(currentModifiers).intersection(.deviceIndependentFlagsMask)
        return modifiers.contains(.option) && !modifiers.contains(.control) && !modifiers.contains(.command)
    }
}
