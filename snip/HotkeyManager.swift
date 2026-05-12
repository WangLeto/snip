import AppKit

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var monitor: Any?

    private let keyCodeMap: [Int: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8,
        83: 0, 84: 1, 85: 2, 86: 3, 87: 4, 88: 5, 89: 6, 91: 7, 92: 8,
    ]

    private let relevantModifiers: NSEvent.ModifierFlags = [.control, .command, .option, .shift, .capsLock, .function]

    private init() {}

    func startMonitoring() {
        guard AXIsProcessTrusted() else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    func restartMonitoring() {
        stopMonitoring()
        startMonitoring()
    }

    private func handleEvent(_ event: NSEvent) {
        let flag = AppState.shared.modifierFlag
        let current = event.modifierFlags.intersection(relevantModifiers)

        guard current == flag || current == [flag, .numericPad] else { return }

        guard let index = keyCodeMap[Int(event.keyCode)] else { return }

        DockManager.shared.toggleApp(at: index)
    }
}
