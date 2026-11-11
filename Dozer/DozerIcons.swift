import Cocoa
import Defaults

public final class DozerIcons {
    static var shared = DozerIcons()
    private var dozerIcons: [HelperstatusIcon] = []
    private var timerToCheckUserInteraction = Timer()
    private var timerToHideDozerIcons = Timer()
    private var startupHideTimer: Timer?
    private var previousApp = NSRunningApplication()
    private let nativeVisibility: NativeMenuBarVisibility? = {
        if #available(macOS 27, *) {
            return NativeMenuBarVisibility()
        }
        return nil
    }()
    private var nativeNormalLeft: HelperstatusIcon?
    private var lastNativeError: String?
    private var applicationLaunchObserver: NSObjectProtocol?

    private init() {
        dozerIcons.append(NormalStatusIcon())

        if !hideBothDozerIcons  || !Defaults[.isShortcutSet] {
            dozerIcons.append(NormalStatusIcon())
        }

        if enableRemoveDozerIcon {
            dozerIcons.append(RemoveStatusIcon())
        }

        if hideStatusBarIconsAfterDelay {
            startTimer()
        }

        Defaults.observe(.isShortcutSet) { change in
            self.triggerHideBothDozerIcons()
        }
        .tieToLifetime(of: self)

        if nativeVisibility != nil {
            applicationLaunchObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self, let nativeVisibility = self.nativeVisibility,
                      let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      application.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                    return
                }
                let state = nativeVisibility.requestedState
                guard state != .expanded else {
                    return
                }
                self.applyNativeVisibility(hideNormal: state.hideNormal, hideRemove: state.hideRemove)
            }
        }
    }

    deinit {
        if let observer = applicationLaunchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func startUserInteractionTimer() {
        stopUserInteractionTimer()
        guard Defaults[.hideAfterDelayEnabled] else {
            stopUserInteractionTimer()
            return
        }
        timerToCheckUserInteraction = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.isUserInteractingWithStatusBar() {
                self.resetTimer()
            }
        }
    }

    private func stopUserInteractionTimer() {
        timerToCheckUserInteraction.invalidate()
    }

    // MARK: Observe changes to settings
    public var hideStatusBarIconsAtLaunch: Bool = Defaults[.hideAtLaunchEnabled] {
        didSet {
            Defaults[.hideAtLaunchEnabled] = self.hideStatusBarIconsAtLaunch
        }
    }

    public var hideStatusBarIconsAfterDelay: Bool = Defaults[.hideAfterDelayEnabled] {
        didSet {
            Defaults[.hideAfterDelayEnabled] = self.hideStatusBarIconsAfterDelay
            if hideStatusBarIconsAfterDelay {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }

    public var hideBothDozerIcons: Bool = Defaults[.noIconMode] {
        didSet {
            Defaults[.noIconMode] = self.hideBothDozerIcons
            triggerHideBothDozerIcons()
        }
    }

    public func triggerHideBothDozerIcons() {
        if nativeVisibility != nil { showAll() }
        let normalStatusIconsCount = dozerIcons.filter { $0.type == .normal}.count
        if hideBothDozerIcons && Defaults[.isShortcutSet] {
            if normalStatusIconsCount == 2 {
                let rightDozerIcon = get(dozerIcon: .normalRight)
                dozerIcons.removeAll { $0 === rightDozerIcon }
            }
        } else if !hideBothDozerIcons && Defaults[.isShortcutSet] || !Defaults[.isShortcutSet] {
            if normalStatusIconsCount == 1 {
                show()
                dozerIcons.append(NormalStatusIcon())
            }
        }
        show()
    }

    public var enableRemoveDozerIcon: Bool = Defaults[.removeDozerIconEnabled] {
        didSet {
            Defaults[.removeDozerIconEnabled] = self.enableRemoveDozerIcon
            if enableRemoveDozerIcon {
                dozerIcons.append(RemoveStatusIcon())
            } else {
                dozerIcons.removeAll { $0.type == .remove }
            }
            showAll()
        }
    }

    public var enableIconAndMenu: Bool = Defaults[.showIconAndMenuEnabled] {
        didSet {
            Defaults[.showIconAndMenuEnabled] = self.enableIconAndMenu
            if self.enableIconAndMenu == false {
                _ = DozerIcons.toggleDockIcon(showIcon: false)
                AppDelegate.shared.preferencesWindowController.show(preferencePane: .general)
            }
        }
    }

    public var iconFontSize: Int = Defaults[.iconSize] {
        didSet {
            Defaults[.iconSize] = self.iconFontSize
            for icon in dozerIcons {
                icon.setSize()
            }
        }
    }

    public var buttonPadding: CGFloat = Defaults[.buttonPadding] {
        didSet {
            Defaults[.buttonPadding] = self.buttonPadding
            for icon in dozerIcons {
                icon.setSize()
            }
        }
    }

    // MARK: Public methods
    public func hide() {
        if nativeVisibility != nil {
            applyNativeVisibility(hideNormal: true, hideRemove: enableRemoveDozerIcon)
            return
        }
        perform(action: .hide, statusIcon: .remove)
        perform(action: .hide, statusIcon: .normalLeft)
        if Defaults[.noIconMode] && Defaults[.isShortcutSet] {
            perform(action: .hide, statusIcon: .normalRight)
        }
        didHideStatusBarIcons()
        hideIconAndMenu()
    }

    public func hideAtLaunch() {
        startupHideTimer?.invalidate()
        if hideStatusBarIconsAtLaunch {
            if #available(macOS 11.0, *) {
                startupHideTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                   self.hide()
                }
            } else {
                self.hide()
            }
        }
    }

    public func show() {
        if nativeVisibility != nil {
            applyNativeVisibility(hideNormal: false, hideRemove: enableRemoveDozerIcon)
            return
        }
        resetTimer()
        perform(action: .hide, statusIcon: .remove)
        perform(action: .show, statusIcon: .normalLeft)
        if Defaults[.noIconMode] {
            perform(action: .show, statusIcon: .normalRight)
        }
        didShowStatusBarIcons()
        showIconAndMenu()
    }

    public func toggle() {
        if let nativeVisibility = nativeVisibility {
            if nativeVisibility.requestedState.hideNormal { show() } else { hide() }
            return
        }
        if get(dozerIcon: .normalLeft).isShown {
            hide()
        } else {
            show()
        }
    }

    public func toggleRemove() {
        if let nativeVisibility = nativeVisibility {
            applyNativeVisibility(hideNormal: nativeVisibility.requestedState.hideNormal,
                                  hideRemove: !nativeVisibility.requestedState.hideRemove && enableRemoveDozerIcon)
            return
        }
        if get(dozerIcon: .remove).isShown {
            perform(action: .hide, statusIcon: .remove)
        } else {
            perform(action: .show, statusIcon: .remove)
        }
    }

    public func showIconAndMenu() {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != AppInfo.bundleIdentifier {
            previousApp = frontmost
        }
        if Defaults[.showIconAndMenuEnabled] {
            _ = DozerIcons.toggleDockIcon(showIcon: true)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    public func hideIconAndMenu() {
        if Defaults[.showIconAndMenuEnabled] {
            _ = DozerIcons.toggleDockIcon(showIcon: false)
            if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == AppInfo.bundleIdentifier {
                previousApp.activate()
            }
        }
    }

    /// Force show all Dozer icons
    public func showAll() {
        startupHideTimer?.invalidate()
        if nativeVisibility != nil {
            applyNativeVisibility(hideNormal: false, hideRemove: false)
            return
        }
        perform(action: .show, statusIcon: .remove)
        perform(action: .show, statusIcon: .normalLeft)
        perform(action: .show, statusIcon: .normalRight)
        didShowStatusBarIcons()
    }

    public func handleOptionClick() {
        if let nativeVisibility = nativeVisibility {
            let hideRemove = !nativeVisibility.requestedState.hideNormal && !nativeVisibility.requestedState.hideRemove
            applyNativeVisibility(hideNormal: false, hideRemove: hideRemove && enableRemoveDozerIcon)
            return
        }
        showIconAndMenu()
        if get(dozerIcon: .normalLeft).isShown {
            DozerIcons.shared.perform(
                action: .toggle,
                statusIcon: .remove
            )
        } else {
            DozerIcons.shared.perform(
                action: .show,
                statusIcon: .normalLeft
            )
            DozerIcons.shared.perform(
                action: .show,
                statusIcon: .remove
            )
        }
        stopUserInteractionTimer()
        startUserInteractionTimer()
        resetTimer()
    }

    // MARK: Show/hide lifecycle
    private func didShowStatusBarIcons() {
        startUserInteractionTimer()
    }

    private func didHideStatusBarIcons() {
        stopTimer()
        stopUserInteractionTimer()
    }

    private func willHideStatusBarIcons() {
        guard Defaults[.hideAfterDelayEnabled] else {
            return
        }

        // don't hide on user interaction with menu bar
        guard !isUserInteractingWithStatusBar() else {
            resetTimer()
            return
        }

        DozerIcons.shared.hide()
    }

    // MARK: timerToHideDozerIcons methods
    private func startTimer() {
        guard Defaults[.hideAfterDelayEnabled] else {
            stopTimer()
            return
        }
        timerToHideDozerIcons = Timer.scheduledTimer(withTimeInterval: Defaults[.hideAfterDelay], repeats: false) { (_: Timer) -> Void in
            self.willHideStatusBarIcons()
        }
    }

    private func stopTimer() {
        timerToHideDozerIcons.invalidate()
    }

    func resetTimer() {
        self.stopTimer()
        self.startTimer()
    }

    // MARK: Private methods
    private func applyNativeVisibility(hideNormal: Bool, hideRemove: Bool, completion: ((Error?) -> Void)? = nil) {
        guard let nativeVisibility = nativeVisibility else {
            return
        }
        let left = nativeNormalLeft ?? get(dozerIcon: .normalLeft)
        nativeNormalLeft = left
        let remove = dozerIcons.first { $0.type == .remove }
        func accessibilityFrame(_ frame: CGRect?) -> CGRect? {
            guard var frame = frame, let primaryScreen = NSScreen.screens.first else {
                return nil
            }
            frame.origin.y = primaryScreen.frame.maxY - frame.maxY
            return frame
        }
        let state = MenuBarVisibilityState(hideNormal: hideNormal, hideRemove: hideRemove)
        let normalFrame = accessibilityFrame(left.frameOnScreen)
        let removeFrame = accessibilityFrame(remove?.frameOnScreen)
        let screenFrame = accessibilityFrame(left.statusIcon.button?.window?.screen?.frame)
        nativeVisibility.apply(state, normal: normalFrame, remove: removeFrame, screen: screenFrame) { [weak self] error in
            guard let self = self else {
                return
            }
            let applied = nativeVisibility.requestedState
            for icon in self.dozerIcons {
                let shouldHide: Bool
                if icon.type == .remove {
                    shouldHide = applied.hideRemove
                } else {
                    shouldHide = applied.hideNormal && (icon === left || self.hideBothDozerIcons && Defaults[.isShortcutSet])
                }
                if shouldHide { icon.hide() } else { icon.show() }
            }
            if applied == .expanded { self.nativeNormalLeft = nil }
            if applied.hideNormal {
                self.didHideStatusBarIcons()
                self.hideIconAndMenu()
            } else {
                self.resetTimer()
                self.didShowStatusBarIcons()
                self.showIconAndMenu()
            }
            if let error = error {
                self.stopTimer()
                self.stopUserInteractionTimer()
                guard self.lastNativeError != error.localizedDescription else {
                    completion?(error)
                    return
                }
                self.lastNativeError = error.localizedDescription
                let alert = NSAlert()
                alert.messageText = "Dozer could not change menu bar visibility"
                alert.informativeText = error.localizedDescription
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
            } else {
                self.lastNativeError = nil
            }
            completion?(error)
        }
    }

    public func recoverVisibility(completion: @escaping (Error?) -> Void = { _ in }) {
        startupHideTimer?.invalidate()
        stopTimer()
        stopUserInteractionTimer()
        guard nativeVisibility != nil else {
            showAll()
            stopTimer()
            stopUserInteractionTimer()
            completion(nil)
            return
        }
        applyNativeVisibility(hideNormal: false, hideRemove: false) { [weak self] error in
            self?.stopTimer()
            self?.stopUserInteractionTimer()
            completion(error)
        }
    }

    public func restoreBeforeQuitting() {
        startupHideTimer?.invalidate()
        stopTimer()
        stopUserInteractionTimer()
        nativeVisibility?.restore()
        for icon in dozerIcons { icon.show() }
    }

    /// Will fail silently if statusIcon does not exist
    private func perform(action: StatusIconAction, statusIcon: DozerIcon) {
        if statusIcon == .remove {
            guard Defaults[.removeDozerIconEnabled] else {
                return
            }
        }
        let theStatusIcon: HelperstatusIcon = get(dozerIcon: statusIcon)
        switch action {
        case .show:
            theStatusIcon.show()
        case .hide:
            theStatusIcon.hide()
        case .toggle:
            theStatusIcon.toggle()
        }
    }

    /// Will crash if trying to get DozerIcon which does not exist in the menu bar
    private func get(dozerIcon: DozerIcon) -> HelperstatusIcon {
        if let left = nativeNormalLeft {
            if dozerIcon == .normalLeft {
                return left
            }
            if dozerIcon == .normalRight {
                return dozerIcons.first { $0.type == .normal && $0 !== left } ?? left
            }
        }
        var normalStatusIconsXPosition: [CGFloat] = []
        for statusIcon in dozerIcons where statusIcon.type == .normal {
            normalStatusIconsXPosition.append(statusIcon.xPositionOnScreen)
        }
        switch dozerIcon {
        case .remove:
            guard let removeStatusIcon = dozerIcons.first(where: { $0.type == .remove }) else {
                fatalError("Failed getting remove status icon")
            }
            return removeStatusIcon
        case .normalLeft:
            guard let leftStatusIcon = dozerIcons.first(where: { $0.type == .normal && $0.xPositionOnScreen == normalStatusIconsXPosition.min() }) else {
                fatalError("Failed getting status icon on the left")
            }
            return leftStatusIcon
        case .normalRight:
            guard let rightStatusIcon = dozerIcons.first(where: { $0.type == .normal && $0.xPositionOnScreen == normalStatusIconsXPosition.max() }) else {
                fatalError("Failed getting status icon on the right")
            }
            return rightStatusIcon
        }
    }

    /// hide and show dock icon and thus its menu bar: to free up space to show more menu bar icons
    public class func toggleDockIcon(showIcon state: Bool) -> Bool {
        if state {
            return NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        } else {
            return NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
        }
    }

    /// Determines if the user is interacting with the menu bar based on level, owner and y-coordinate
    private func isUserInteractingWithStatusBar() -> Bool {
        if #available(macOS 27, *) {
            let mouse = NSEvent.mouseLocation
            if NSScreen.screens.contains(where: { screen in
                let height = max(NSStatusBar.system.thickness, screen.safeAreaInsets.top)
                return CGRect(
                    x: screen.frame.minX,
                    y: screen.frame.maxY - height,
                    width: screen.frame.width,
                    height: height
                ).contains(mouse)
            }) {
                return true
            }
            let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
            return windows.contains {
                ($0[kCGWindowLayer as String] as? Int) == NSWindow.Level.popUpMenu.rawValue
            }
        }
        let windowListType = CGWindowListOption.optionOnScreenOnly
        guard let windowInfoList = CGWindowListCopyWindowInfo(windowListType, kCGNullWindowID) as NSArray? as? [[String: AnyObject]] else {
            return false
        }
        var statusBarAppsWindowInfo: [Window] = []

        for windowInfo in windowInfoList {
            guard let window = Window(windowInfo),
                window.owner != "Dozer" else {
                    continue
            }

            if window.isStatusIcon {
                statusBarAppsWindowInfo.append(window)
            }
        }

        for windowInfo in windowInfoList {
            guard let window = Window(windowInfo) else { continue }
            guard window.isStatusIcon == false else { continue }

            for statusBarApp in statusBarAppsWindowInfo {
                guard statusBarApp.owner == window.owner else { continue }
                guard (statusBarApp.y + 22...statusBarApp.y + 37).contains(window.y) else { continue }

                return true
            }
        }

        return false
    }

    /// Wrapper class for CGWindowList
    private class Window {
        var x: Int = 0
        var y: Int = 0
        var width: Int = 0
        var height: Int = 0

        var level: Int
        var owner: String

        init?(_ windowInfo: [String: AnyObject]) {
            guard let level = windowInfo[kCGWindowLayer as String] as? Int else {
                return nil
            }
            guard let owner = windowInfo[kCGWindowOwnerName as String] as? String else {
                return nil
            }

            self.level = level
            self.owner = owner

            let bounds: [String: Int] = windowInfo[kCGWindowBounds as String] as! [String: Int]
            for item in bounds {
                switch item.key {
                case "X":
                    x = item.value
                case "Y":
                    y = item.value
                case "Width":
                    width = item.value
                case "Height":
                    height = item.value
                default:
                    continue
                }
            }
        }

        var isStatusIcon: Bool {
            guard level == 25 && height >= 22 && height <= 37 else {
                return false
            }
            return true
        }
    }
}
