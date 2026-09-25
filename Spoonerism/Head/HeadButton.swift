import SwiftUI

/// Role: Head. Seat phase for ButtonStyle. Righted is selected. Muffed is error. Colour is never the only miss signal.
enum HeadPhase: Equatable, Sendable {
    case open
    case swapped
    case muffed
    case righted
}

/// Role: Head. Native Button for one seated Line word. Mend fuses here. Whole chrome is the target. Min 44pt.
struct HeadButton: View {
    let head: Head
    let phase: HeadPhase
    let isBusy: Bool
    var isArmed: Bool = true
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: action) {
            Text(head.spoken)
                .font(MarrowType.font(.headline, size: typeSize))
                .strikethrough(phase == .muffed, color: MarrowInk.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, MarrowSpace.card)
                .frame(minHeight: MarrowSpace.hit, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
        }
        .buttonStyle(HeadSeatStyle(phase: phase))
        .disabled(!isArmed || phase == .righted || phase == .muffed || isBusy)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(phase == .righted ? .isSelected : AccessibilityTraits())
    }

    private var label: String {
        switch phase {
        case .open:
            return head.spoken
        case .swapped:
            return "\(head.spoken), first letter swapped"
        case .righted:
            return "\(head.spoken), filed"
        case .muffed:
            return "\(head.spoken), miss"
        }
    }

    private var hint: String {
        switch phase {
        case .open:
            return "Files this word if it swapped its first letter."
        case .swapped:
            return "Puts both first letters back."
        case .righted, .muffed:
            return "Already filed."
        }
    }
}

/// Role: Head. Covers default, pressed, focused, disabled, and selected. Chip radius. Flat fill.
struct HeadSeatStyle: ButtonStyle {
    var phase: HeadPhase

    func makeBody(configuration: Configuration) -> some View {
        HeadSeatBody(configuration: configuration, phase: phase)
    }
}

private struct HeadSeatBody: View {
    let configuration: ButtonStyle.Configuration
    let phase: HeadPhase
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(foreground)
            .background(fill, in: RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous)
                    .stroke(stroke, lineWidth: strokeWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
            .scaleEffect(pressed && isEnabled ? MarrowMotion.pressScale(reduceMotion) : 1)
            .opacity(tileOpacity(pressed: pressed))
            .animation(MarrowMotion.snap(reduceMotion), value: pressed)
            .animation(MarrowMotion.snap(reduceMotion), value: phase)
            .animation(MarrowMotion.snap(reduceMotion), value: isFocused)
            .animation(MarrowMotion.snap(reduceMotion), value: isEnabled)
    }

    private var fill: Color {
        switch phase {
        case .open, .righted:
            return MarrowInk.surface
        case .swapped:
            return MarrowInk.accent
        case .muffed:
            return MarrowInk.muted.opacity(0.28)
        }
    }

    private var foreground: Color {
        switch phase {
        case .open, .righted:
            return MarrowInk.ink
        case .swapped:
            return MarrowInk.surface
        case .muffed:
            return MarrowInk.muted
        }
    }

    private var stroke: Color {
        if isFocused { return MarrowInk.ink }
        if phase == .muffed { return MarrowInk.ink.opacity(0.55) }
        if phase == .righted || phase == .swapped { return MarrowInk.accent }
        return MarrowInk.ink.opacity(0.12)
    }

    private var strokeWidth: CGFloat {
        if isFocused { return 2 }
        return 1
    }

    private func tileOpacity(pressed: Bool) -> Double {
        if phase == .muffed { return 0.72 }
        if !isEnabled && phase != .righted { return 0.5 }
        if pressed { return 0.88 }
        return 1
    }
}
