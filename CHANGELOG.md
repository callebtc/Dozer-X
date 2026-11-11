# Changelog

## Unreleased
Fixed:
* Restore menu bar hiding on macOS 27 using the native visibility service, with Accessibility permission and fail-open error handling.
* Reconfigure native visibility in place when switching groups, and restore unrestricted visibility before releasing the assertion.
* Refresh the native allowlist when an application launches so unclassified new icons are not silently hidden.
* Recognize Option-click when a forwarded status item event omits the current Option modifier.
* Remove Preferences window animations and restore Dozer's dots at startup even if macOS remembers them as hidden.

## Version 4.2.0
New features:
* Configure amount of seconds to hide the icons after #104. @blakedgordon
* Resize icons and padding capability added #101. @blakedgordon

Fixed:
* Fix both dozer icons from being hidden #105. @blakedgordon

Thank you @blakedgordon for the contributions🙌

## Version 4.1.0
New features:
* Hide status bar icons at launch #78. @aonez

Fixed:
* Reduce CPU usage when "Hide status bar icons after 10 seconds" is checked #78. @aonez

Thank you @aonez for the contributions🙌

## Version 4
New features:
* ”Remove”-icon. Additional icon to hide/show icons with `option+click`
* Auto-hide status bar icons #22
* ”No Icon”-mode. Hide/show only using keyboard shortcut

Other:
* Improved UI in preferences
