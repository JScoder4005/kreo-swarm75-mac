import Combine
import Foundation
import KreoCore
import ServiceManagement

public struct Profile: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var settings: LightingSettings

    public init(name: String, settings: LightingSettings) {
        self.name = name
        self.settings = settings
    }
}

public final class AppState: ObservableObject {
    @Published public var settings: LightingSettings { didSet { save(); scheduleSend() } }
    @Published public var profiles: [Profile] { didSet { save() } }
    @Published public var autoApply: Bool { didSet { save() } }
    @Published public private(set) var connected = false
    @Published public private(set) var problem: String?
    @Published public private(set) var lastResult = ""

    private let link: KeyboardLink?
    private let persist: Bool
    private let defaults = UserDefaults.standard
    private var pending: DispatchWorkItem?

    /// The real app: talks to the keyboard and remembers settings.
    public convenience init() { self.init(link: KeyboardLink(), persist: true) }

    /// For design snapshots: no keyboard access, nothing saved.
    public static func preview(_ settings: LightingSettings, profiles: [Profile] = [], connected: Bool) -> AppState {
        let s = AppState(link: nil, persist: false)
        s.settings = settings
        s.profiles = profiles
        s.connected = connected
        s.lastResult = connected ? "Applied" : ""
        return s
    }

    private init(link: KeyboardLink?, persist: Bool) {
        self.link = link
        self.persist = persist
        settings = persist ? Self.load(LightingSettings.self, "settings") ?? LightingSettings() : LightingSettings()
        profiles = persist ? Self.load([Profile].self, "profiles") ?? [] : []
        autoApply = persist ? defaults.object(forKey: "autoApply") as? Bool ?? true : true
        guard let link else { return }
        link.$connected.assign(to: &$connected)
        link.$problem.assign(to: &$problem)
        link.onAttach = { [weak self] in
            guard let self, self.autoApply else { return }
            self.apply()
        }
    }

    public func apply() {
        guard let link, link.connected else { lastResult = "Plug in the cable to apply"; return }
        lastResult = link.send(settings) ? "Applied" : "Send failed. Unplug and plug in again."
    }

    public func use(_ profile: Profile) { settings = profile.settings }

    public func saveProfile(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        profiles.removeAll { $0.name == trimmed }
        profiles.append(Profile(name: trimmed, settings: settings))
    }

    public func delete(_ profile: Profile) { profiles.removeAll { $0.id == profile.id } }

    public var launchAtLogin: Bool {
        get { persist && SMAppService.mainApp.status == .enabled }
        set {
            guard persist else { return }
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                lastResult = "Open at login needs Kreo in Applications"
            }
            objectWillChange.send()
        }
    }

    // Controls fire many changes; send once they settle, and only when the keyboard is there.
    private func scheduleSend() {
        guard let link else { return }
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, link.connected else { return }
            self.apply()
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private func save() {
        guard persist else { return }
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
