import SwiftUI

/// Role: Onset. Snap press and sheet travel. Reduce Motion keeps fade and drops the 0.97 scale.
enum MarrowSnap {
    static let pressScale: CGFloat = 0.97
    static let sheetScale: CGFloat = 0.96
    static let duration: Double = 0.16
}

enum MarrowMotion {
    static func snap(_ reduceMotion: Bool) -> Animation {
        if reduceMotion {
            return .easeOut(duration: MarrowSnap.duration)
        }
        return .easeOut(duration: MarrowSnap.duration)
    }

    static func pressScale(_ reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 1 : MarrowSnap.pressScale
    }

    static func sheetScale(_ reduceMotion: Bool, appeared: Bool) -> CGFloat {
        if reduceMotion { return 1 }
        return appeared ? 1 : MarrowSnap.sheetScale
    }
}

/// Role: Onset. Asset names from section 13. Views never invent a second kit.
enum MarrowArt {
    static let splash = "spn_Splash"
    static let onboarding1 = "spn_Onboarding1"
    static let onboarding2 = "spn_Onboarding2"
    static let onboarding3 = "spn_Onboarding3"
    static let emptyHome = "spn_EmptyHome"
    static let emptyList = "spn_EmptyList"
    static let cardBackdrop = "spn_CardBackdrop"
    static let controlFace = "spn_ControlFace"
    static let twistHero = "spn_TwistHero"
    static let successMark = "spn_SuccessMark"
    static let headerDecor = "spn_HeaderDecor"
}

/// Role: Onset. Warm short copy. Periods, never an em dash. Counts stay in MarrowFigures.
enum MarrowCopy {
    static let fluentHeadline = "Save a painting first."
    static let fluentLine = "Then you can tap a swapped word."
    static let exploreEmptyHeadline = "The shelf is quiet."
    static let exploreEmptyLine = "Search Prado, then save a work."
    static let savedEmptyHeadline = "Nothing filed yet."
    static let savedEmptyLine = "Tap a word that swapped its first letter."
    static let spoonedJob = "Tap the swapped word"
    static let spoonedNext = "A first letter moved. Tap that word."
    static let writeFailed = "Write failed. Try that tap again."
    static let recoverHeadline = "The save could not be read."
    static let recoverLine = "The save could not be read. A quiet start is up."
    static let deviceSection = "This device"
    static let hitsMissesSection = "Hits and misses"
    static let recentHits = "Recent hits"
    static let hitsLabel = "Hits"
    static let missesLabel = "Misses"
    static let filedLabel = "Filed"
    static let undoHint = "Removes the newest hit or miss."

    static func verb(sign: OnsetSign) -> String {
        switch sign {
        case .fluent:
            return "Save a painting"
        case .idle:
            return "Pick a painting"
        case .spooned:
            return spoonedJob
        case .mended:
            return "This painting is set"
        }
    }

    static func nextTap(sign: OnsetSign) -> String {
        switch sign {
        case .fluent:
            return fluentLine
        case .idle:
            return "Maker or title will paint as words."
        case .spooned:
            return spoonedNext
        case .mended:
            return "Pick another saved painting."
        }
    }

    static func signLabel(_ sign: OnsetSign) -> String {
        switch sign {
        case .fluent: return "Waiting"
        case .idle: return "Ready"
        case .spooned: return "Live"
        case .mended: return "Filed"
        }
    }

    static func fieldLabel(_ field: LineField) -> String {
        switch field {
        case .artist: return "Maker"
        case .title: return "Title"
        }
    }

    static func fault(_ error: Error) -> String {
        if let fault = error as? OnsetFault {
            switch fault {
            case .mendOnIdle:
                return "Tap a live word first."
            case .alreadySpooned:
                return "Finish this painting first."
            case .thinField:
                return "Need two unlike first letters."
            case .unknownHead:
                return "That word is not on this painting."
            case .alreadyRighted:
                return "Those first letters are already right."
            case .alreadyGrey:
                return "That word already missed."
            case .nothingToPeel:
                return "Nothing to undo."
            case .emptyObjectID:
                return "This work has no object id."
            case .unknownWork:
                return "That work is not saved."
            }
        }
        if let fault = error as? CatalogFault {
            return seek(fault)
        }
        return writeFailed
    }

    static func seek(_ fault: CatalogFault) -> String {
        switch fault {
        case .cancelled:
            return "Search stopped."
        case .missing:
            return "Prado had no match. The bundled shelf is here."
        case .refused:
            return "Prado refused the search. The bundled shelf is here."
        case .transport:
            return "Search could not reach Prado. The bundled shelf is here."
        case .malformed:
            return "Search could not be read. The bundled shelf is here."
        }
    }
}

/// Role: Onset. MendMark counts, MuffMark counts, and YYYYMMDD day keys go through NumberFormatter.
enum MarrowFigures {
    static func whole(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func daykey(_ value: Int) -> String {
        let year = value / 10_000
        let month = (value / 100) % 100
        let day = value % 100
        return "\(plain(year)).\(plain(month, digits: 2)).\(plain(day, digits: 2))"
    }

    private static func plain(_ value: Int, digits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = digits
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

/// Role: Onset. Pill CTA for Spoon and empty-page actions. Default, pressed, focused, disabled, loading. Wipe is ink, never accent.
struct MarrowPillStyle: ButtonStyle {
    enum Tone {
        case spoon
        case quiet
        case wipe
    }

    var tone: Tone = .spoon
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        MarrowPillBody(configuration: configuration, tone: tone, isLoading: isLoading)
    }
}

private struct MarrowPillBody: View {
    let configuration: ButtonStyle.Configuration
    let tone: MarrowPillStyle.Tone
    let isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        HStack(spacing: MarrowSpace.inner) {
            if isLoading {
                ProgressView()
                    .tint(labelInk)
            }
            configuration.label
        }
        .font(MarrowType.font(.headline, size: typeSize))
        .foregroundStyle(labelInk)
        .frame(maxWidth: .infinity)
        .frame(minHeight: MarrowSpace.hit)
        .padding(.horizontal, MarrowSpace.card)
        .background(fill, in: RoundedRectangle(cornerRadius: MarrowRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MarrowRadius.card, style: .continuous)
                .stroke(MarrowInk.ink, lineWidth: isFocused ? 2 : 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.card, style: .continuous))
        .scaleEffect(pressed && isEnabled ? MarrowMotion.pressScale(reduceMotion) : 1)
        .opacity(visualOpacity(pressed: pressed))
        .animation(MarrowMotion.snap(reduceMotion), value: pressed)
        .animation(MarrowMotion.snap(reduceMotion), value: isEnabled)
        .animation(MarrowMotion.snap(reduceMotion), value: isLoading)
        .animation(MarrowMotion.snap(reduceMotion), value: isFocused)
    }

    private var fill: Color {
        switch tone {
        case .spoon:
            return isEnabled ? MarrowInk.accent : MarrowInk.muted.opacity(0.35)
        case .quiet:
            return MarrowInk.surface
        case .wipe:
            return MarrowInk.ink
        }
    }

    private var labelInk: Color {
        switch tone {
        case .spoon, .wipe:
            return MarrowInk.surface
        case .quiet:
            return MarrowInk.ink
        }
    }

    private func visualOpacity(pressed: Bool) -> Double {
        if !isEnabled { return 0.48 }
        if isLoading { return 0.7 }
        if pressed { return 0.88 }
        return 1
    }
}

/// Role: Onset. Icon-only sheet chrome. Hit the whole 44pt tile.
struct MarrowGlyphStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MarrowGlyphBody(configuration: configuration)
    }
}

private struct MarrowGlyphBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .frame(minWidth: MarrowSpace.hit, minHeight: MarrowSpace.hit)
            .background(MarrowInk.surface, in: RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous)
                    .stroke(MarrowInk.ink, lineWidth: isFocused ? 2 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
            .scaleEffect(pressed && isEnabled ? MarrowMotion.pressScale(reduceMotion) : 1)
            .opacity(!isEnabled ? 0.42 : (pressed ? 0.88 : 1))
            .animation(MarrowMotion.snap(reduceMotion), value: pressed)
            .animation(MarrowMotion.snap(reduceMotion), value: isEnabled)
            .animation(MarrowMotion.snap(reduceMotion), value: isFocused)
    }
}

/// Role: Work. Pressed row for Explore shelf and Form rows. Flat fill, no second shadow.
struct MarrowRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MarrowRowBody(configuration: configuration)
    }
}

private struct MarrowRowBody: View {
    let configuration: ButtonStyle.Configuration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: MarrowRadius.card, style: .continuous)
                    .stroke(MarrowInk.ink, lineWidth: isFocused ? 2 : 0)
            )
            .scaleEffect(pressed && isEnabled ? MarrowMotion.pressScale(reduceMotion) : 1)
            .opacity(!isEnabled ? 0.55 : (pressed ? 0.88 : 1))
            .animation(MarrowMotion.snap(reduceMotion), value: pressed)
            .animation(MarrowMotion.snap(reduceMotion), value: isEnabled)
    }
}

/// Role: Onset. Sheet scale 0.96 to 1 plus fade. Reduce Motion is opacity only.
struct MarrowSheetHost<Content: View>: View {
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(MarrowInk.background.ignoresSafeArea())
            .preferredColorScheme(.light)
            .tint(MarrowInk.accent)
            .scaleEffect(MarrowMotion.sheetScale(reduceMotion, appeared: appeared))
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(MarrowMotion.snap(reduceMotion)) {
                    appeared = true
                }
            }
    }
}

/// Role: Work. Commons thumb. Framed and clipped so scaledToFill cannot cover a neighbor.
struct MarrowThumb: View {
    var url: URL?
    var side: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        MarrowInk.surface
                    }
                }
            } else {
                MarrowInk.surface
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
        .clipped()
        .accessibilityHidden(true)
    }
}

extension View {
    func marrowHit() -> some View {
        frame(minWidth: MarrowSpace.hit, minHeight: MarrowSpace.hit)
            .contentShape(Rectangle())
    }

    func marrowFlat(_ radius: CGFloat = MarrowRadius.card, fill: Color = MarrowInk.surface) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension Image {
    func marrowCutout(maxWidth: CGFloat? = .infinity, maxHeight: CGFloat) -> some View {
        resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .clipped()
            .accessibilityHidden(true)
    }
}
