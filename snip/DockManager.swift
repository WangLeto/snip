import AppKit

struct DockApp {
    let name: String
    let bundleID: String?
    let url: URL
}

@MainActor
final class DockManager {
    static let shared = DockManager()

    private init() {}

    func loadPinnedApps() -> [DockApp] {
        let dockPath = NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist"
        guard let data = FileManager.default.contents(atPath: dockPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dockDict = plist as? [String: Any],
              let persistentApps = dockDict["persistent-apps"] as? [[String: Any]] else {
            return []
        }

        var apps: [DockApp] = []

        for app in persistentApps {
            guard apps.count < 9,
                  let tileData = app["tile-data"] as? [String: Any],
                  let fileData = tileData["file-data"] as? [String: Any],
                  let rawURL = fileData["_CFURLString"] as? String else {
                continue
            }

            var urlString = rawURL.replacingOccurrences(of: "\0", with: "")
            if urlString.hasPrefix("file://~") {
                urlString = urlString.replacingOccurrences(of: "file://~", with: "file://" + NSHomeDirectory())
            }

            guard let url = URL(string: urlString) else { continue }

            let bundle = Bundle(url: url)
            let bundleID = tileData["bundle-identifier"] as? String
                ?? fileData["bundle-identifier"] as? String
                ?? bundle?.bundleIdentifier

            if bundleID == "com.apple.finder" { continue }

            let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? fileData["_CFURLName"] as? String
                ?? url.deletingPathExtension().lastPathComponent

            apps.append(DockApp(name: name, bundleID: bundleID, url: url))
        }

        return apps
    }

    func toggleApp(at index: Int) {
        let apps = loadPinnedApps()
        guard index < apps.count else { return }
        let app = apps[index]
        let runningApps = NSWorkspace.shared.runningApplications

        if let bid = app.bundleID, let runningApp = runningApps.first(where: { $0.bundleIdentifier == bid }) {
            if runningApp.isActive {
                runningApp.hide()
            } else {
                runningApp.unhide()
                runningApp.activate(options: [.activateIgnoringOtherApps])
            }
        } else {
            NSWorkspace.shared.open(app.url)
        }
    }
}
