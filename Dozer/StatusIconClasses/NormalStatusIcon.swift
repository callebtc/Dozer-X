import Cocoa

class NormalStatusIcon: HelperstatusIcon {
    enum ClickAction: Equatable {
        case toggle, optionClick, preferences, ignore
    }

    override init() {
        super.init()
        type = .normal
    }

    override func statusIconClicked(_: AnyObject?) {
        guard let currentEvent = NSApp.currentEvent else {
            return
        }

        switch Self.clickAction(
            eventType: currentEvent.type,
            eventModifiers: currentEvent.modifierFlags,
            currentModifiers: NSEvent.modifierFlags
        ) {
        case .toggle:
            DozerIcons.shared.toggle()
        case .optionClick:
            DozerIcons.shared.handleOptionClick()
        case .preferences:
            AppDelegate.shared.preferencesWindowController.show(preferencePane: .general)
        case .ignore:
            break
        }
    }

    static func clickAction(
        eventType: NSEvent.EventType,
        eventModifiers: NSEvent.ModifierFlags,
        currentModifiers: NSEvent.ModifierFlags
    ) -> ClickAction {
        if eventType == .rightMouseDown {
            return .preferences
        }
        guard eventType == .leftMouseDown,
              !eventModifiers.union(currentModifiers).contains(.command) else {
            return .ignore
        }
        return isOptionClick(eventModifiers: eventModifiers, currentModifiers: currentModifiers) ? .optionClick : .toggle
    }

    static func isOptionClick(eventModifiers: NSEvent.ModifierFlags, currentModifiers: NSEvent.ModifierFlags) -> Bool {
        let modifiers = eventModifiers.union(currentModifiers).intersection(.deviceIndependentFlagsMask)
        return modifiers.contains(.option) && !modifiers.contains(.control) && !modifiers.contains(.command)
    }
}
