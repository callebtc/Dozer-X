# Dozer-X

Dozer-X is a maintained fork of [Dozer](https://github.com/Mortennn/Dozer), the lightweight macOS menu bar utility for hiding status bar icons.

The original Dozer project has not been updated since 2020 and its release binaries are Intel-only. Dozer-X keeps the same core behavior, but updates the project so it builds and runs natively on modern macOS without Rosetta.

## Goals

- Keep Dozer's original minimal menu bar workflow.
- Avoid adding new product features unless they are needed for modern macOS support.
- Ship native Apple Silicon builds.
- Replace deprecated tooling and dependencies.
- Keep the app robust for future macOS releases.

## What Changed In Dozer-X 5.0.0

- Raised the minimum supported macOS version to macOS 14 Sonoma.
- Added native Apple Silicon support.
- Migrated dependencies from Carthage to Swift Package Manager.
- Replaced MASShortcut with [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).
- Updated Sparkle from 1.x to Sparkle 2.x.
- Switched launch-at-login support to the modern macOS 13+ `SMAppService` path through [LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern).
- Removed the Objective-C bridging header and legacy Carthage build scripts.
- Updated XcodeGen, SwiftGen, and SwiftLint usage for current developer tools.
- Fixed startup behavior for modern AppKit so the menu bar icons are created reliably.
- Fixed the Preferences crash caused by recursive UserDefaults change handling.

## Install

Download the latest release from the [Dozer-X releases page](https://github.com/callebtc/Dozer-X/releases/latest), unzip it, and move `Dozer.app` to `/Applications`.

Homebrew Cask still points at the deprecated upstream Dozer release and is not recommended for Dozer-X.

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac

## Usage

Dozer adds two small dots to the menu bar by default. A third dot can be enabled in Preferences.

- Move menu bar icons you want to hide to the left of the second Dozer dot.
- Left-click a Dozer dot to hide or show that group of menu bar icons.
- Right-click a Dozer dot to open Preferences.
- Option-click a Dozer dot to show or hide the optional third group, if enabled.
- Hold Command (`Command`) and drag menu bar icons to rearrange them.

Selective Option-click hiding requires **Enable 'remove' Dozer icon** in General Preferences. Move its smaller dot to the left of the normal hiding divider. Icons to the left of the smaller dot form the optional group; icons between the dividers form the normal group.

## macOS 27 Compatibility

macOS 27 no longer lets oversized separators push other menu bar icons offscreen. Dozer-X uses the system's native visibility service on macOS 27 and later; macOS 14–26 retain the original separator behavior.

- Install `Dozer.app` in `/Applications` before running it.
- Grant Dozer access in **System Settings → Privacy & Security → Accessibility** when prompted, then click a Dozer dot again. This permission is needed to find the icons to the left of the separator.
- Visibility is controlled per application, across all displays. If an app's reported icons occupy both hidden and visible sections, its most visible placement wins. Apps without readable positions, and positions reported outside the separator's display, are left visible.
- Newly launched applications remain visible until their icons can be classified from an unrestricted layout.
- System controls such as Control Center, Wi-Fi, and the clock remain visible.
- Show all icons before rearranging the dots or moving apps between sections. Restricted icons do not report reliable positions, so Dozer keeps the last unrestricted layout until all groups are expanded again.
- Dozer explicitly invalidates each native assertion before activating its replacement. Repeated activation on the same native object can leave earlier restrictions behind. Dozer adds no fade or artificial reveal delay; any menu bar animation performed by macOS is system-controlled.
- Startup and reopening request a fresh unrestricted configuration even if this instance has not hidden anything. A second cooperating Dozer instance asks the running copy to reveal every group and exits without creating its own separators or restrictions. Older copies are asked to quit gracefully, and Dozer waits for them to exit before taking control.
- Recovery after another instance or an interrupted hiding session leaves every group expanded, without immediately applying hide-at-launch or auto-hide. Your preferences and icon order are preserved; click a dot or use your shortcut when you want to hide again.
- From Terminal, request recovery with `"/Applications/Dozer-X.app/Contents/MacOS/Dozer" --recover-menu-bar`. This also reveals all groups in an already running cooperating copy.
- Dozer can release its own restrictions, not assertions owned by other menu bar managers. Quit any other menu bar manager if icons remain hidden after reopening Dozer.
- This support is experimental because macOS exposes the visibility service through the private `MenuBarClientCore` framework. Dozer checks the service at runtime and releases its restrictions on errors, timeouts, quit, and ordinary termination signals.

The implementation is adapted from [upstream Dozer PR #212](https://github.com/Mortennn/Dozer/pull/212) and [Hidden Bar](https://github.com/dwarvesf/hidden). See `THIRD_PARTY_NOTICES.md` for the third-party license.

## Development

Dozer-X uses XcodeGen and Swift Package Manager.

```sh
make build
```

Generate, build, and run the app:

```sh
make run
```

The generated `Dozer.xcodeproj` is intentionally ignored by Git.

## Relationship To Original Dozer

Dozer-X is a fork of [Mortennn/Dozer](https://github.com/Mortennn/Dozer). The original project remains the source of the app's concept and UI behavior, but it is deprecated for current macOS use because its published builds are old and Intel-only.

Dozer-X keeps the app name as `Dozer` in most system-facing places for continuity, while the About pane identifies this fork as `Dozer-X`.

## License

Dozer-X is licensed under the Mozilla Public License 2.0, following the original Dozer project.
