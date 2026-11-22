import SwiftUI

/// Five segments for the keyboard's five hardware levels. Stored as 0, 25, 50, 75, 100.
struct LevelBar: View {
    let title: String
    @Binding var value: Int
    let tint: Color
    var enabled = true

    private var level: Int { min(max(Int((Double(value) / 25).rounded()), 0), 4) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                Spacer()
                Text("\(level + 1) of 5")
                    .font(.system(.callout, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Button { value = i * 25 } label: {
                        Capsule()
                            .fill(i <= level ? tint : Color.secondary.opacity(0.22))
                            .frame(height: 10)
                            .contentShape(Rectangle().inset(by: -6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) level \(i + 1)")
                }
            }
        }
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(level + 1) of 5")
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: value = min(level + 1, 4) * 25
            case .decrement: value = max(level - 1, 0) * 25
            @unknown default: break
            }
        }
    }
}

struct EffectTile: View {
    let name: String
    let symbol: String
    let selected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? tint : .secondary)
                    .frame(width: 18)
                Text(name)
                    .font(.callout.weight(selected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selected ? tint.opacity(0.14) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(selected ? tint : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
