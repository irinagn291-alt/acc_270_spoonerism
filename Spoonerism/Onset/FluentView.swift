import SwiftUI

/// Role: Onset. Empty Quiz. Fluent is an onset write, never a pushed scene. Full page cutout, headline, line, Explore.
struct FluentView: View {
    let headline: String
    let line: String
    let actionTitle: String
    var isLoading: Bool = false
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarrowSpace.step(2)) {
            ViewThatFits(in: .vertical) {
                copyStack(showsSpacer: true)
                ScrollView {
                    copyStack(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
            }
            Button(actionTitle, action: action)
                .buttonStyle(MarrowPillStyle(tone: .spoon, isLoading: isLoading))
                .marrowHit()
        }
        .padding(.horizontal, MarrowSpace.outer)
        .padding(.top, MarrowSpace.card)
        .padding(.bottom, MarrowSpace.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MarrowInk.background)
    }

    private func copyStack(showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.step(2)) {
            Image(MarrowArt.emptyHome)
                .marrowCutout(maxWidth: .infinity, maxHeight: MarrowSpace.step(22))
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
    }
}

/// Role: Work. Full-page empty or error for sheets. Cutout, one headline, one line, bottom full-width CTA.
struct ShelfQuiet: View {
    let art: String
    let headline: String
    let line: String
    let actionTitle: String
    var isLoading: Bool = false
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarrowSpace.step(2)) {
            ViewThatFits(in: .vertical) {
                copyStack(showsSpacer: true)
                ScrollView {
                    copyStack(showsSpacer: false)
                }
                .scrollIndicators(.hidden)
            }
            Button(actionTitle, action: action)
                .buttonStyle(MarrowPillStyle(tone: .spoon, isLoading: isLoading))
                .marrowHit()
        }
        .padding(.horizontal, MarrowSpace.outer)
        .padding(.top, MarrowSpace.card)
        .padding(.bottom, MarrowSpace.outer)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MarrowInk.background)
    }

    private func copyStack(showsSpacer: Bool) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.step(2)) {
            Image(art)
                .marrowCutout(maxWidth: .infinity, maxHeight: MarrowSpace.step(22))
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
    }
}
