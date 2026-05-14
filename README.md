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
