import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Snip")
                .font(.headline)

            Divider()

            modifierSection
            Divider()
            loginSection
            Divider()
            accessibilitySection
            Divider()
            shortcutsSection

            Spacer(minLength: 4)

            HStack {
                Spacer()
                Button("Quit Snip") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(width: 300)
    }

    private var modifierSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modifier Key")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker("", selection: $appState.modifierKey) {
                Text("Ctrl ⌃").tag("control")
                Text("Cmd ⌘").tag("command")
                Text("Option ⌥").tag("option")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var loginSection: some View {
        Toggle(isOn: Binding(
            get: { appState.loginItemEnabled },
            set: { appState.setLoginItem(enabled: $0) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at Login")
                Text("Automatically start when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility Permission")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                Image(systemName: appState.accessibilityEnabled
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill")
                    .foregroundColor(appState.accessibilityEnabled ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.accessibilityEnabled ? "Permission Granted" : "Permission Required")
                        .font(.body)

                    if !appState.accessibilityEnabled {
                        Text("Snip needs Accessibility access to monitor keyboard shortcuts globally.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !appState.accessibilityEnabled {
                    Spacer()
                    Button("Grant") {
                        appState.requestAccessibilityPermission()
                        if !appState.accessibilityEnabled {
                            appState.openAccessibilitySettings()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Shortcuts")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if appState.dockApps.isEmpty {
                Text("No apps found in Dock. Check that your Dock has pinned applications.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(appState.dockApps.enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 4) {
                        Text("\(modifierSymbol)\(i + 1)")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(item.name)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var modifierSymbol: String {
        switch appState.modifierKey {
        case "command": return "⌘"
        case "option": return "⌥"
        default: return "⌃"
        }
    }
}

#Preview {
    SettingsView()
        .padding()
}
