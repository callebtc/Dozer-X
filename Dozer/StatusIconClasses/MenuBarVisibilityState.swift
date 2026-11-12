struct MenuBarVisibilityState: Equatable {
    var hideNormal = false
    var hideRemove = false
    static let expanded = MenuBarVisibilityState()

    func applying(_ action: MenuBarVisibilityAction, extraEnabled: Bool) -> Self {
        switch action {
        case .hide:
            return Self(hideNormal: true, hideRemove: extraEnabled)
        case .showNormal:
            return Self(hideNormal: false, hideRemove: extraEnabled)
        case .toggleNormal:
            return Self(hideNormal: !hideNormal, hideRemove: extraEnabled)
        case .toggleExtra:
            return Self(hideNormal: hideNormal, hideRemove: extraEnabled && !hideRemove)
        case .optionClick:
            return Self(hideNormal: false, hideRemove: extraEnabled && self == .expanded)
        case .toggleAll:
            return self == .expanded ? Self(hideNormal: true, hideRemove: extraEnabled) : .expanded
        case .revealAll:
            return .expanded
        }
    }
}

enum MenuBarVisibilityAction {
    case hide, showNormal, toggleNormal, toggleExtra, optionClick, toggleAll, revealAll
}
