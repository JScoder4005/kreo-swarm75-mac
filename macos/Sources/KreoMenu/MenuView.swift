import AppKit
import KreoCore
import SwiftUI

struct MenuView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var link: KeyboardLink
    @State private var profileName = ""

    private let swatches: [RGB] = [
        RGB(255, 59, 59), RGB(255, 138, 31), RGB(255, 210, 31), RGB(61, 220, 132),
        RGB(23, 200, 200), RGB(47, 123, 255), RGB(138, 92, 255), RGB(255, 79, 216), RGB(255, 255, 255),
    ]
    private let levels = ["1", "2", "3", "4", "5"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            colorSection
            effectSection
            levelSlider("Brightness", value: $state.settings.brightness)
            levelSlider("Speed", value: $state.settings.speed)
                .disabled(!(effect?.animated ?? true))
            Divider()
            profilesSection
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
    }

    private var effect: Effect? { KreoProtocol.effects.first { $0.id == state.settings.effect } }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(link.connected ? Color.green : Color.secondary).frame(width: 8, height: 8)
                Text(link.connected ? "Keyboard connected (cable)" : "Keyboard not on cable")
                    .font(.headline)
                Spacer()
            }
            if let problem = link.problem {
                Text(problem).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color")
                Spacer()
                ColorPicker("Color", selection: colorBinding, supportsOpacity: false).labelsHidden()
            }
            HStack(spacing: 6) {
                ForEach(swatches.indices, id: \.self) { i in
                    let c = swatches[i]
                    Button { state.settings.color = c } label: {
                        Circle().fill(Color(rgb: c)).frame(width: 22, height: 22)
                            .overlay(Circle().stroke(Color.primary, lineWidth: state.settings.color == c ? 2 : 0))
                    }
                    .buttonStyle(.plain)
                    .help("Use this color")
                }
            }
        }
    }

    private var effectSection: some View {
        Picker("Effect", selection: $state.settings.effect) {
            ForEach(KreoProtocol.effects) { Text($0.name).tag($0.id) }
        }
    }

    private func levelSlider(_ title: String, value: Binding<Int>) -> some View {
        // The keyboard has 5 brightness and speed levels; the slider snaps to them.
        let step = Binding<Double>(
            get: { Double(value.wrappedValue) / 25 },
            set: { value.wrappedValue = Int($0.rounded()) * 25 }
        )
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(levels[min(Int(step.wrappedValue), 4)]).foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: step, in: 0...4, step: 1)
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profiles").font(.subheadline.weight(.semibold))
            if state.profiles.isEmpty {
                Text("Set a look, name it, and save it.").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(state.profiles) { p in
                HStack {
                    Circle().fill(Color(rgb: p.settings.color)).frame(width: 10, height: 10)
                    Button(p.name) { state.use(p) }.buttonStyle(.link)
                    Spacer()
                    Button { state.delete(p) } label: { Image(systemName: "xmark") }
                        .buttonStyle(.borderless)
                        .help("Delete \(p.name)")
                }
            }
            HStack {
                TextField("Name this look", text: $profileName).onSubmit(saveProfile)
                Button("Save", action: saveProfile).disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Apply automatically when plugged in", isOn: $state.autoApply)
            Toggle("Open at login", isOn: Binding(get: { state.launchAtLogin }, set: { state.launchAtLogin = $0 }))
            HStack {
                Button("Apply now") { state.apply() }.disabled(!link.connected)
                Text(state.lastResult).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            Text("Changes are saved in the keyboard and stay on Bluetooth after you unplug.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(rgb: state.settings.color) },
            set: { new in
                guard let c = NSColor(new).usingColorSpace(.sRGB) else { return }
                state.settings.color = RGB(UInt8(c.redComponent * 255 + 0.5),
                                           UInt8(c.greenComponent * 255 + 0.5),
                                           UInt8(c.blueComponent * 255 + 0.5))
            }
        )
    }

    private func saveProfile() {
        state.saveProfile(named: profileName)
        profileName = ""
    }
}

extension Color {
    init(rgb: RGB) {
        self.init(.sRGB, red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255)
    }
}
