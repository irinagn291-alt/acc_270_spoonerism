import SwiftUI

/// Role: Onset. One-shot cover. Three pages. Continue full width at the bottom. Skip writes defaults. Re-runnable from Settings.
struct OnboardingView: View {
    var onSkip: () -> Void
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                if page < 2 {
                    Button("Skip", action: onSkip)
                        .font(MarrowType.font(.caption, size: typeSize))
                        .foregroundStyle(MarrowInk.ink)
                        .marrowHit()
                        .buttonStyle(MarrowGlyphStyle())
                        .accessibilityLabel("Skip onboarding")
                }
            }
            .padding(.horizontal, MarrowSpace.outer)

            ViewThatFits(in: .vertical) {
                pageSwitch(showsSpacer: true)
                ScrollView {
                    pageSwitch(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
            }
            .id(page)
            .animation(MarrowMotion.snap(reduceMotion), value: page)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            HStack(spacing: MarrowSpace.gap) {
                ForEach(0 ..< 3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous)
                        .fill(index == page ? MarrowInk.accent : MarrowInk.surface)
                        .frame(
                            width: index == page ? MarrowSpace.step(3) : MarrowSpace.inner,
                            height: MarrowSpace.inner
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, MarrowSpace.outer)
            .padding(.bottom, MarrowSpace.inner)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Page \(MarrowFigures.whole(page + 1)) of \(MarrowFigures.whole(3))"
            )

            Button("Continue") {
                if page < 2 {
                    page += 1
                } else {
                    onFinish()
                }
            }
            .buttonStyle(MarrowPillStyle(tone: .spoon, isLoading: false))
            .padding(.horizontal, MarrowSpace.outer)
            .padding(.bottom, MarrowSpace.outer)
        }
        .background(MarrowInk.background.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func pageSwitch(showsSpacer: Bool) -> some View {
        switch page {
        case 0:
            pageBody(
                art: MarrowArt.onboarding1,
                headline: "Save a painting.",
                line: "Keep Prado works on this device. Home is the line, not a museum walk.",
                showsSpacer: showsSpacer
            )
        case 1:
            pageBody(
                art: MarrowArt.onboarding2,
                headline: "Tap a swapped word.",
                line: "Two first letters trade. Word order stays. Tap a word that swapped its first letter.",
                showsSpacer: showsSpacer
            )
        default:
            pageBody(
                art: MarrowArt.onboarding3,
                headline: "File the painting.",
                line: "A true tap shelves it. Misses stay with kept paintings.",
                showsSpacer: showsSpacer
            )
        }
    }

    private func pageBody(art: String, headline: String, line: String, showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.step(2)) {
            Image(art)
                .marrowCutout(maxWidth: .infinity, maxHeight: MarrowSpace.step(36))
            Text(headline)
                .font(MarrowType.font(.display, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(3)
            Text(line)
                .font(MarrowType.font(.body, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(4)
            if showsSpacer {
                Spacer(minLength: MarrowSpace.gap)
            }
        }
        .padding(.horizontal, MarrowSpace.outer)
        .padding(.top, MarrowSpace.card)
    }
}
