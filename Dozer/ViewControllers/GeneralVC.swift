import Cocoa
import Preferences
import KeyboardShortcuts
import LaunchAtLogin
import Sparkle
import Defaults

final class General: NSViewController, PreferencePane {
    let preferencePaneIdentifier = Preferences.PaneIdentifier.general
    let preferencePaneTitle: String = "General"
    let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

    override var nibName: NSNib.Name? { "General" }

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    @IBOutlet private var LaunchAtLoginCheckbox: NSButton!
    @IBOutlet private var CheckForUpdatesCheckbox: NSButton!
    @IBOutlet private var HideStatusBarIconsAtLaunchCheckbox: NSButton!
    @IBOutlet private var HideStatusBarIconsAfterDelayCheckbox: NSButton!
    @IBOutlet private var HideStatusBarIconsSecondsPopUpButton: NSPopUpButton!
    @IBOutlet private var HideBothDozerIconsCheckbox: NSButton!
    @IBOutlet private var EnableRemoveDozerIconCheckbox: NSButton!
    @IBOutlet private var ShowIconAndMenuCheckbox: NSButton!
    @IBOutlet private var FontSizePopUpButton: NSPopUpButton!
    @IBOutlet private var ButtonPaddingPopUpButton: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        LaunchAtLoginCheckbox.focusRingType = .none

        LaunchAtLoginCheckbox.isChecked = LaunchAtLogin.isEnabled
        CheckForUpdatesCheckbox.isChecked = updaterController.updater.automaticallyChecksForUpdates

        HideStatusBarIconsAtLaunchCheckbox.isChecked = Defaults[.hideAtLaunchEnabled]
        HideStatusBarIconsAfterDelayCheckbox.isChecked = Defaults[.hideAfterDelayEnabled]
        HideBothDozerIconsCheckbox.isChecked = Defaults[.noIconMode]
        EnableRemoveDozerIconCheckbox.isChecked = Defaults[.removeDozerIconEnabled]
        ShowIconAndMenuCheckbox.isChecked = Defaults[.showIconAndMenuEnabled]
        HideStatusBarIconsSecondsPopUpButton.selectItem(withTitle: "\(Int(Defaults[.hideAfterDelay])) seconds")
        FontSizePopUpButton.selectItem(withTitle: "\(Int(Defaults[.iconSize])) px")
        ButtonPaddingPopUpButton.selectItem(withTitle: "\(Int(Defaults[.buttonPadding])) px")

        addKeyboardShortcutRecorder()
        configureEnabledNoIconCheckbox()

        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.configureEnabledNoIconCheckbox()
        }
    }

    private func addKeyboardShortcutRecorder() {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleMenuItems)
        recorder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recorder)

        NSLayoutConstraint.activate([
            recorder.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recorder.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
        ])
    }

    @IBAction private func launchAtLoginClicked(_ sender: NSButton) {
        LaunchAtLogin.isEnabled = (sender.state == .on)
    }

    @IBAction private func automaticallyCheckForUpdatesClicked(_ sender: NSButton) {
        updaterController.updater.automaticallyChecksForUpdates = (sender.state == .on)
        CheckForUpdatesCheckbox.isChecked = updaterController.updater.automaticallyChecksForUpdates
    }

    @IBAction private func hideStatusBarIconsAtLaunchClicked(_ sender: NSButton) {
        DozerIcons.shared.hideStatusBarIconsAtLaunch = HideStatusBarIconsAtLaunchCheckbox.isChecked
    }

    @IBAction private func hideStatusBarIconsAfterDelayClicked(_ sender: NSButton) {
        DozerIcons.shared.hideStatusBarIconsAfterDelay = HideStatusBarIconsAfterDelayCheckbox.isChecked
    }

    @IBAction private func hideStatusBarIconsSecondsUpdated(_ sender: NSPopUpButton) {
        Defaults[.hideAfterDelay] = TimeInterval(HideStatusBarIconsSecondsPopUpButton.selectedTag())
        DozerIcons.shared.resetTimer()
    }

    @IBAction private func hideBothDozerIconsClicked(_ sender: NSButton) {
        DozerIcons.shared.hideBothDozerIcons = HideBothDozerIconsCheckbox.isChecked
    }

    @IBAction private func showIconAndMenuClicked(_ sender: NSButton) {
        DozerIcons.shared.enableIconAndMenu = ShowIconAndMenuCheckbox.isChecked
    }

    @IBAction private func fontSizeChanged(_ sender: NSPopUpButton) {
        DozerIcons.shared.iconFontSize = FontSizePopUpButton.selectedTag()
    }

    @IBAction private func buttonPaddingChanged(_ sender: NSPopUpButton) {
        DozerIcons.shared.buttonPadding = CGFloat(ButtonPaddingPopUpButton.selectedTag())
    }

    @IBAction private func enableRemoveDozerIconClicked(_ sender: NSButton) {
        DozerIcons.shared.enableRemoveDozerIcon = EnableRemoveDozerIconCheckbox.isChecked
    }

    private func configureEnabledNoIconCheckbox() {
        let hasShortcut = KeyboardShortcuts.getShortcut(for: .toggleMenuItems) != nil
        HideBothDozerIconsCheckbox.isEnabled = hasShortcut
        Defaults[.isShortcutSet] = hasShortcut
    }
}
