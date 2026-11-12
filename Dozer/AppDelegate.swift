import Cocoa
import Sparkle
import Defaults
import Preferences
import KeyboardShortcuts
import Darwin

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!

    private let instanceCoordinator = DozerInstanceCoordinator()
    private var recoveryObserver: NSObjectProtocol?
    private var terminationSignals: [DispatchSourceSignal] = []
    private var didInitializeIcons = false
    private var recoveryRequested = ProcessInfo.processInfo.arguments.contains("--recover-menu-bar")

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationWillTerminate(_: Notification) {
        if didInitializeIcons { DozerIcons.shared.restoreBeforeQuitting() }
        instanceCoordinator.stop()
        if let observer = recoveryObserver { DistributedNotificationCenter.default().removeObserver(observer) }
        for source in terminationSignals { source.cancel() }
    }

    func applicationDidFinishLaunching(_: Notification) {
        for signalNumber in [SIGTERM, SIGINT] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { NSApp.terminate(nil) }
            source.resume()
            terminationSignals.append(source)
        }
        recoveryObserver = DistributedNotificationCenter.default().addObserver(
            forName: DozerInstanceCoordinator.restoreNotification,
            object: AppInfo.bundleIdentifier,
            queue: .main
        ) { [weak self] _ in
            self?.requestRecovery()
        }
        instanceCoordinator.start { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(.primary(let recovered)):
                self.initializeIcons(recovered: recovered)
            case .success(.secondary):
                DistributedNotificationCenter.default().postNotificationName(
                    DozerInstanceCoordinator.restoreNotification,
                    object: AppInfo.bundleIdentifier,
                    userInfo: nil,
                    deliverImmediately: true
                )
                NSApp.terminate(nil)
            case .failure(let error):
                let alert = NSAlert()
                alert.messageText = "Dozer could not recover menu bar icons"
                alert.informativeText = error.localizedDescription
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
                NSApp.terminate(nil)
            }
        }
    }

    private func initializeIcons(recovered: Bool) {
        let needsRecovery = recovered || recoveryRequested || NativeMenuBarVisibility.needsRecovery
        KeyboardShortcuts.onKeyUp(for: .toggleMenuItems) {
            DozerIcons.shared.toggleAll()
        }

        Defaults[.isShortcutSet] = KeyboardShortcuts.getShortcut(for: .toggleMenuItems) != nil

        didInitializeIcons = true
        _ = DozerIcons.toggleDockIcon(showIcon: false)
        DozerIcons.shared.recoverVisibility { [weak self] error in
            guard let self = self, error == nil, !needsRecovery, !self.recoveryRequested else {
                return
            }
            DozerIcons.shared.resetTimer()
            DozerIcons.shared.hideAtLaunch()
        }
    }

    private func requestRecovery() {
        recoveryRequested = true
        if didInitializeIcons { DozerIcons.shared.recoverVisibility() }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        requestRecovery()
        return true
    }

    lazy var preferences: [PreferencePane] = [
        Dozer(),
        General()
    ]

    lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: preferences,
        style: .toolbarItems,
        animated: false,
        hidesToolbarForSingleItem: true
    )

    var sparkleUpdaterController: SPUStandardUpdaterController {
        updaterController
    }
}
