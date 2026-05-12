import AppKit
import ServiceManagement
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var modifierKey: String = UserDefaults.standard.string(forKey: "modifierKey") ?? "control" {
        didSet { saveModifierKey() }
    }

    @Published var loginItemEnabled: Bool = false
    @Published var accessibilityEnabled: Bool = false
    @Published var dockApps: [DockAppItem] = []

    private init() {
        updateAccessibilityStatus()
        updateLoginItemStatus()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let previous = self.accessibilityEnabled
                self.updateAccessibilityStatus()
                if !previous && self.accessibilityEnabled {
                    HotkeyManager.shared.startMonitoring()
                }
            }
        }
    }

    private func saveModifierKey() {
        UserDefaults.standard.set(modifierKey, forKey: "modifierKey")
        HotkeyManager.shared.restartMonitoring()
    }

    func updateAccessibilityStatus() {
        accessibilityEnabled = AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        accessibilityEnabled = trusted
        if trusted {
            HotkeyManager.shared.startMonitoring()
        }
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func refreshDockApps() {
        dockApps = DockManager.shared.loadPinnedApps().map { app in
            DockAppItem(name: app.name, bundleID: app.bundleID, url: app.url)
        }
    }

    func updateLoginItemStatus() {
        if #available(macOS 13.0, *) {
            loginItemEnabled = SMAppService.mainApp.status == .enabled
        }
    }

    func setLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                loginItemEnabled = enabled
            } catch {
                print("Login item error: \(error)")
            }
        }
    }

    var modifierFlag: NSEvent.ModifierFlags {
        switch modifierKey {
        case "command": return .command
        case "option": return .option
        default: return .control
        }
    }
}

struct DockAppItem: Identifiable {
    let id = UUID()
    let name: String
    let bundleID: String?
    let url: URL
}
