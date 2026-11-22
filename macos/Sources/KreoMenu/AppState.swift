import Foundation
import KreoCore
import ServiceManagement

struct Profile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var settings: LightingSettings
}

final class AppState: ObservableObject {
    @Published var settings: LightingSettings { didSet { save(); scheduleSend() } }
    @Published var profiles: [Profile] { didSet { save() } }
    @Published var autoApply: Bool { didSet { save() } }
    @Published private(set) var lastResult = ""

    let link = KeyboardLink()
    private let defaults = UserDefaults.standard
    private var pending: DispatchWorkItem?

    init() {
        settings = Self.load(LightingSettings.self, "settings") ?? LightingSettings()
        profiles = Self.load([Profile].self, "profiles") ?? []
        autoApply = defaults.object(forKey: "autoApply") as? Bool ?? true
        link.onAttach = { [weak self] in
            guard let self, self.autoApply else { return }
            self.apply()
        }
    }

    func apply() {
        guard link.connected else { lastResult = "Plug in the cable to apply"; return }
        lastResult = link.send(settings) ? "Applied" : "Send failed. Unplug and plug in again."
    }

    func use(_ profile: Profile) { settings = profile.settings }

    func saveProfile(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        profiles.removeAll { $0.name == trimmed }
        profiles.append(Profile(name: trimmed, settings: settings))
    }

    func delete(_ profile: Profile) { profiles.removeAll { $0.id == profile.id } }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                lastResult = "Launch at login needs the app in /Applications"
            }
            objectWillChange.send()
        }
    }

    // Sliders fire many changes; send once they settle, and only when the keyboard is there.
    private func scheduleSend() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.link.connected else { return }
            self.apply()
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private func save() {
        let enc = JSONEncoder()
        defaults.set(try? enc.encode(settings), forKey: "settings")
        defaults.set(try? enc.encode(profiles), forKey: "profiles")
        defaults.set(autoApply, forKey: "autoApply")
    }

    private static func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
