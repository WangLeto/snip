# Snip

A tiny macOS menu-bar utility that lets you toggle the first 9 apps pinned to your Dock with a single modifier-key chord.

Press `⌃1` to launch / focus / hide the first Dock app, `⌃2` for the second, and so on up to `⌃9`. Choose `⌃` (Control), `⌘` (Command), or `⌥` (Option) as the modifier.

## Features

- **Global hotkeys**: `Modifier + 1~9` toggles the corresponding Dock app
  - Not running → launch it
  - Running but not focused → focus it
  - Focused → hide it
- **Auto-syncs with the Dock**: reads `com.apple.dock` and refreshes when you rearrange pinned apps
- **Menu-bar only**: no Dock icon, no main window — just a status item with a popover
- **Configurable modifier**: pick Control / Command / Option
- **Launch at login** via `SMAppService`
- **Accessibility permission flow**: one-tap "Grant" button triggers the system prompt and registers the app with TCC

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ to build

## Build

Open `snip.xcodeproj` in Xcode and Run (`⌘R`).

For a distributable build that actually plays well with the TCC permission system, build then copy the product out of `DerivedData`:

```bash
xcodebuild -project snip.xcodeproj -scheme snip -configuration Release build
APP="$(xcodebuild -project snip.xcodeproj -scheme snip -configuration Release -showBuildSettings | awk -F'= ' '/ BUILT_PRODUCTS_DIR /{print $2}')/snip.app"
cp -R "$APP" /Applications/
codesign --force --deep --sign - /Applications/snip.app
open /Applications/snip.app
```

> Running directly from Xcode often makes the Accessibility permission unreliable because the DerivedData path and ad-hoc signature can change between builds. Always test from `/Applications` once you're past the first iteration.

## Usage

1. Launch Snip — a lightning-bolt icon appears in the menu bar.
2. Click the icon to open settings:
   - Pick your modifier key (`⌃` / `⌘` / `⌥`)
   - Click **Grant** to enable Accessibility (required for global hotkeys)
   - Optionally turn on **Launch at Login**
3. Pin up to 9 apps to your Dock. The popover lists which shortcut maps to which app.
4. Press `Modifier + 1~9` anywhere to toggle.

The Finder icon, if present in your Dock, is skipped automatically.

## Permissions

Snip needs the **Accessibility** permission to register a global key-down monitor (`NSEvent.addGlobalMonitorForEvents`). Clicking **Grant** invokes `AXIsProcessTrustedWithOptions(prompt: true)`, which registers the app with macOS TCC and opens the system prompt. If you've previously denied the prompt, the button falls back to opening **System Settings → Privacy & Security → Accessibility** so you can flip the toggle manually.

After granting, Snip detects the change automatically (on app reactivation and via a periodic poll) and starts monitoring without requiring a restart.

## Project Layout

```
snip/
├── snipApp.swift        # @main, hooks AppDelegate
├── AppDelegate.swift    # NSStatusItem + popover, lifecycle
├── AppState.swift       # Observable state, permission + login-item logic
├── HotkeyManager.swift  # Global modifier-number hotkey monitor
├── DockManager.swift    # Reads pinned apps from com.apple.dock plist
├── SettingsView.swift   # SwiftUI popover UI
└── Assets.xcassets/     # AppIcon
```

## Sharing the Build

The project uses ad-hoc signing (`Sign to Run Locally`), so recipients will see a Gatekeeper warning on first launch:

```bash
# Package
ditto -c -k --sequesterRsrc --keepParent /Applications/snip.app ~/Desktop/snip.zip
```

Tell the recipient to either:
- Right-click `snip.app` → **Open** → **Open** in the confirmation dialog, or
- Run `xattr -dr com.apple.quarantine /Applications/snip.app` if the OS reports the app as "damaged"

For a friction-free install, ship with a Developer ID Application certificate + notarization (requires an Apple Developer account).

## License

MIT
