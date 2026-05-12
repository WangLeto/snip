import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()

        AppState.shared.refreshDockApps()
        AppState.shared.updateAccessibilityStatus()
        AppState.shared.updateLoginItemStatus()
        HotkeyManager.shared.startMonitoring()

        observeDockChanges()
        startAccessibilityPolling()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stopMonitoring()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "bolt.horizontal.circle.fill",
                accessibilityDescription: "Snip"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView())
    }

    private func observeDockChanges() {
        let center = DistributedNotificationCenter.default()

        _ = center.addObserver(
            forName: NSNotification.Name("com.apple.dock.prefchanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        _ = center.addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    private func startAccessibilityPolling() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                let wasEnabled = AppState.shared.accessibilityEnabled
                AppState.shared.updateAccessibilityStatus()
                let isEnabled = AppState.shared.accessibilityEnabled
                if !wasEnabled && isEnabled {
                    HotkeyManager.shared.restartMonitoring()
                } else if wasEnabled && !isEnabled {
                    HotkeyManager.shared.stopMonitoring()
                }
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func refresh() {
        AppState.shared.refreshDockApps()
        AppState.shared.updateAccessibilityStatus()
        AppState.shared.updateLoginItemStatus()
        if AppState.shared.accessibilityEnabled {
            HotkeyManager.shared.restartMonitoring()
        } else {
            HotkeyManager.shared.stopMonitoring()
        }
    }
}
