import AppKit
import KreoCore
import SwiftUI

public struct MenuView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.snapshotMode) private var snapshotMode
    @State private var profileName = ""

    public init() {}

    private static let named: [(id: Int, name: String, symbol: String)] = [
        (1, "Static", "circle.fill"),
        (2, "Rainbow wave", "rainbow"),
        (3, "Breathing", "wind"),
        (7, "Ripples", "dot.radiowaves.left.and.right"),
        (10, "Snake", "point.topleft.down.to.point.bottomright.curvepath"),
        (12, "Trail", "hand.tap.fill"),
    ]
    private static let waves = [4, 5, 6, 8, 11, 13, 15]
    private static let swatches: [RGB] = [
        RGB(255, 59, 59), RGB(255, 138, 31), RGB(255, 210, 31), RGB(61, 220, 132),
        RGB(23, 200, 200), RGB(47, 123, 255), RGB(138, 92, 255), RGB(255, 79, 216), RGB(255, 255, 255),
    ]

    private var tint: Color { Theme.accent(state.settings.color) }
    private var animated: Bool { state.settings.effect != 1 }
    private var usesOwnColors: Bool { [2, 3, 11].contains(state.settings.effect) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            // Fixed height: the window sizes itself to its content, and a Canvas has no natural size.
            KeyboardPreview(settings: state.settings)
                .frame(maxWidth: .infinity)
                .frame(height: 168)
            effectSection
            colorSection
            HStack(alignment: .top, spacing: 20) {
                LevelBar(title: "Brightness", value: $state.settings.brightness, tint: tint)
                LevelBar(title: "Speed", value: $state.settings.speed, tint: tint, enabled: animated)
            }
            Divider()
            profilesSection
            Divider()
            footer
        }
        .padding(20)
        .frame(width: 420)
        // Don't start with the cursor in the profile name field.
        .onAppear { DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) } }
    }

    // MARK: sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Swarm 75").font(.system(.title2, design: .rounded).weight(.bold))
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(state.connected ? Color.green : Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text(statusText).font(.callout).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            if let problem = state.problem {
                Text(problem).font(.callout).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var statusText: String {
        guard state.connected else { return "Plug in the cable to apply" }
        return state.lastResult.isEmpty ? "Connected" : state.lastResult
    }

    private var effectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Effect").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Self.named, id: \.id) { e in
                    EffectTile(name: e.name, symbol: e.symbol, selected: state.settings.effect == e.id, tint: tint) {
                        state.settings.effect = e.id
                    }
                }
            }
            HStack(spacing: 6) {
                Text("More waves").font(.callout).foregroundStyle(.secondary)
                Spacer()
                ForEach(Self.waves, id: \.self) { n in
                    let on = state.settings.effect == n
                    Button { state.settings.effect = n } label: {
                        Text("\(n)")
                            .font(.system(.callout, design: .rounded).weight(on ? .bold : .regular).monospacedDigit())
                            .frame(width: 28, height: 24)
                            .background(Circle().fill(on ? tint.opacity(0.18) : Color.secondary.opacity(0.08)))
                            .overlay(Circle().strokeBorder(on ? tint : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Wave effect \(n)")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Color").font(.headline)
                if usesOwnColors {
                    Text("This effect uses its own colors").font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(Self.swatches.indices, id: \.self) { i in
                    let c = Self.swatches[i]
                    let on = state.settings.color == c
                    Button { state.settings.color = c } label: {
                        Circle().fill(Color(rgb: c))
                            .frame(width: 24, height: 24)
                            .overlay(Circle().strokeBorder(Color.primary.opacity(on ? 0.9 : 0.12), lineWidth: on ? 2 : 1))
                            .padding(2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color \(i + 1)")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
                Spacer(minLength: 4)
                if snapshotMode {
                    // Stand-in for the system color well, which can't render offscreen.
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], center: .center))
                        .frame(width: 38, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.2)))
                } else {
                    ColorPicker("Custom color", selection: colorBinding, supportsOpacity: false).labelsHidden()
                }
            }
        }
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profiles").font(.headline)
            if state.profiles.isEmpty {
                Text("Save the current look to switch back to it in one click.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                FlowRow(spacing: 8) {
                    ForEach(state.profiles) { p in profileChip(p) }
                }
            }
            HStack {
                if snapshotMode {
                    Text("Name this look").foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 7).frame(height: 22)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color(nsColor: .textBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.18)))
                } else {
                    TextField("Name this look", text: $profileName).textFieldStyle(.roundedBorder).onSubmit(saveProfile)
                }
                Button("Save profile", action: saveProfile)
                    .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func profileChip(_ p: Profile) -> some View {
        let on = p.settings == state.settings
        return HStack(spacing: 6) {
            Button { state.use(p) } label: {
                HStack(spacing: 6) {
                    Circle().fill(Color(rgb: p.settings.color)).frame(width: 10, height: 10)
                    Text(p.name).font(.callout.weight(on ? .semibold : .regular))
                }
            }
            .buttonStyle(.plain)
            Button { state.delete(p) } label: {
                Image(systemName: "xmark").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(p.name)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(on ? tint.opacity(0.16) : Color.secondary.opacity(0.08)))
        .overlay(Capsule().strokeBorder(on ? tint : .clear, lineWidth: 1.5))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Apply when plugged in", isOn: $state.autoApply)
                    Toggle("Open at login", isOn: Binding(get: { state.launchAtLogin }, set: { state.launchAtLogin = $0 }))
                }
                Spacer()
                Button("Apply now") { state.apply() }.disabled(!state.connected)
                Button("Quit") { NSApp.terminate(nil) }
            }
            Text("The look is saved in the keyboard, so it stays on Bluetooth after you unplug.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: helpers

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(rgb: state.settings.color) },
            set: { new in
                guard let c = NSColor(new).usingColorSpace(.sRGB) else { return }
                state.settings.color = RGB(UInt8(min(max(c.redComponent, 0), 1) * 255 + 0.5),
                                           UInt8(min(max(c.greenComponent, 0), 1) * 255 + 0.5),
                                           UInt8(min(max(c.blueComponent, 0), 1) * 255 + 0.5))
            }
        )
    }

    private func saveProfile() {
        state.saveProfile(named: profileName)
        profileName = ""
    }
}

/// Wraps chips onto new lines.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (view, point) in zip(subviews, arrange(width: bounds.width, subviews).points) {
            view.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, _ subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            points.append(CGPoint(x: x, y: y))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), points)
    }
}
