import SwiftUI

/// Role: Onset. Locked Quiz. The spoonered Line never leaves. Explore, Saved, and Settings arrive as sheets. Spoon and mend fuse here.
struct QuizView: View {
    @Bindable var desk: OnsetDesk
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if desk.quizIsEmpty {
                idlePage
            } else {
                populated
            }
        }
        .background(MarrowInk.background.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .medium), trigger: desk.mendPulse)
        .animation(MarrowMotion.snap(reduceMotion), value: desk.onset.sign)
        .animation(MarrowMotion.snap(reduceMotion), value: desk.onset.line?.workID)
        .sheet(item: compactCover) { cover in
            coverView(cover)
        }
        .fullScreenCover(item: regularCover) { cover in
            coverView(cover)
        }
    }

    private var idlePage: some View {
        GeometryReader { geo in
            let textWidth = max(geo.size.width - MarrowSpace.outer * 2, MarrowSpace.hit)
            VStack(alignment: .leading, spacing: 0) {
                jobLine(textWidth: textWidth)
                    .padding(.horizontal, MarrowSpace.outer)
                    .padding(.top, MarrowSpace.inner)
                FluentView(
                    headline: desk.recoveredNotice ? MarrowCopy.recoverHeadline : MarrowCopy.fluentHeadline,
                    line: desk.recoveredNotice ? MarrowCopy.recoverLine : MarrowCopy.fluentLine,
                    actionTitle: "Browse"
                ) {
                    desk.present(.explore)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    private var populated: some View {
        GeometryReader { geo in
            let pageWidth = geo.size.width
            let textWidth = max(pageWidth - MarrowSpace.outer * 2, MarrowSpace.hit)
            ViewThatFits(in: .vertical) {
                populatedColumn(textWidth: textWidth, pageHeight: geo.size.height, heroFills: true)
                ScrollView(.vertical) {
                    populatedColumn(textWidth: textWidth, pageHeight: geo.size.height, heroFills: false)
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: pageWidth, height: geo.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func populatedColumn(textWidth: CGFloat, pageHeight: CGFloat, heroFills: Bool) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.gap) {
            jobLine(textWidth: textWidth)
            notices(textWidth: textWidth)
            QuizTile(
                work: desk.displayedWork,
                showSuccess: desk.showSuccess
            )
            .frame(width: textWidth)
            .frame(maxHeight: heroFills ? .infinity : nil)
            .frame(height: heroFills ? nil : max(pageHeight * 0.46, MarrowSpace.step(28)))
            .frame(minHeight: MarrowSpace.step(28))
            .layoutPriority(heroFills ? 1 : 0)
            .clipped()
            captionUnderTile(textWidth: textWidth)
            LineView(desk: desk)
                .frame(width: textWidth, alignment: .leading)
            fusedVerbs
                .frame(width: textWidth, alignment: .leading)
            MendMarkRail(desk: desk, columnWidth: textWidth)
                .frame(width: textWidth, alignment: .leading)
            wordLinks(textWidth: textWidth)
        }
        .padding(.horizontal, MarrowSpace.outer)
        .padding(.top, MarrowSpace.inner)
        .padding(.bottom, MarrowSpace.card)
        .frame(width: pageWidth(textWidth: textWidth), alignment: .topLeading)
        .frame(maxHeight: heroFills ? pageHeight : nil, alignment: .topLeading)
    }

    private func pageWidth(textWidth: CGFloat) -> CGFloat {
        textWidth + MarrowSpace.outer * 2
    }

    private func captionUnderTile(textWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            readable(
                desk.displayedWork?.title ?? "Painting",
                step: .title,
                width: textWidth
            )
            readable(
                desk.displayedWork?.artist ?? "Maker",
                step: .body,
                width: textWidth
            )
            readable(
                "\(MarrowFigures.daykey(desk.dayStamp)) · \(MarrowCopy.signLabel(desk.onset.sign))",
                step: .caption,
                width: textWidth
            )
        }
        .frame(width: textWidth, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(captionVoice)
    }

    private var captionVoice: String {
        let title = desk.displayedWork?.title ?? "Painting"
        let artist = desk.displayedWork?.artist ?? "Maker"
        return "\(title), \(artist), \(MarrowCopy.signLabel(desk.onset.sign))"
    }

    @ViewBuilder
    private func notices(textWidth: CGFloat) -> some View {
        if let fault = desk.onsetFault {
            HStack(alignment: .center, spacing: MarrowSpace.gap) {
                Text(fault)
                    .font(MarrowType.font(.caption, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Retry") {
                    Task { await desk.flush() }
                }
                .font(MarrowType.font(.caption, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .marrowHit()
                .buttonStyle(MarrowGlyphStyle())
                .accessibilityLabel("Retry")
            }
            .padding(MarrowSpace.card)
            .frame(width: textWidth, alignment: .leading)
            .marrowFlat()
        }
        if desk.recoveredNotice {
            wrapped(MarrowCopy.recoverLine, step: .caption, width: textWidth, limit: 4)
                .padding(MarrowSpace.card)
                .frame(width: textWidth, alignment: .leading)
                .marrowFlat()
        }
    }

    private var fusedVerbs: some View {
        HStack(alignment: .center, spacing: MarrowSpace.gap) {
            if desk.onset.sign != .spooned {
                Button {
                    Task { await desk.spoonWork() }
                } label: {
                    HStack(spacing: MarrowSpace.inner) {
                        Image(MarrowArt.controlFace)
                            .resizable()
                            .scaledToFit()
                            .frame(width: MarrowSpace.step(3), height: MarrowSpace.step(3))
                            .accessibilityHidden(true)
                        Text("Spoon")
                    }
                }
                .buttonStyle(MarrowPillStyle(tone: .spoon, isLoading: desk.spoonBusy))
                .disabled(!desk.spoonEnabled)
                .accessibilityHint("Draws a painting that is not filed yet and paints its words.")
            }

            Button {
                Task { await desk.undoNewest() }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(MarrowType.font(.headline, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .frame(minWidth: MarrowSpace.hit, minHeight: MarrowSpace.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MarrowGlyphStyle())
            .disabled(!desk.undoEnabled)
            .accessibilityLabel("Undo")
            .accessibilityHint(MarrowCopy.undoHint)
        }
        .frame(
            maxWidth: .infinity,
            alignment: desk.onset.sign == .spooned ? .trailing : .center
        )
    }

    private func jobLine(textWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            readable(MarrowCopy.verb(sign: desk.onset.sign), step: .display, width: textWidth)
                .accessibilityAddTraits(.isHeader)
            readable(MarrowCopy.nextTap(sign: desk.onset.sign), step: .body, width: textWidth)
        }
        .frame(width: textWidth, alignment: .leading)
    }

    private func wordLinks(textWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.gap) {
            wordChrome("How it works") { desk.present(.spoonMend) }
            wordChrome("Browse") { desk.present(.explore) }
            wordChrome("Kept") { desk.present(.saved) }
            wordChrome("Settings") { desk.present(.settings) }
        }
        .frame(width: textWidth, alignment: .leading)
    }

    private func readable(_ text: String, step: MarrowType.Step, width: CGFloat) -> some View {
        Text(text)
            .font(MarrowType.font(step, size: typeSize))
            .foregroundStyle(MarrowInk.ink)
            .multilineTextAlignment(.leading)
            .lineLimit(4)
            .frame(width: max(width, MarrowSpace.hit), alignment: .leading)
    }

    private func wrapped(_ text: String, step: MarrowType.Step, width: CGFloat, limit: Int) -> some View {
        Text(text)
            .font(MarrowType.font(step, size: typeSize))
            .foregroundStyle(MarrowInk.ink)
            .multilineTextAlignment(.leading)
            .lineLimit(limit)
            .frame(width: max(width, MarrowSpace.hit), alignment: .leading)
    }

    private func wordChrome(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(MarrowType.font(.caption, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(1)
                .frame(minHeight: MarrowSpace.hit, alignment: .leading)
                .padding(.horizontal, MarrowSpace.card)
                .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
        }
        .buttonStyle(MarrowGlyphStyle())
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func coverView(_ cover: MarrowCover) -> some View {
        switch cover {
        case .explore:
            ExploreView(desk: desk)
        case .saved:
            SavedView(desk: desk)
        case .settings:
            SettingsView(desk: desk)
        case .spoonMend:
            SpoonMendSheet(desk: desk)
        }
    }

    private var compactCover: Binding<MarrowCover?> {
        Binding(
            get: { sizeClass == .regular ? nil : desk.cover },
            set: { desk.cover = $0 }
        )
    }

    private var regularCover: Binding<MarrowCover?> {
        Binding(
            get: { sizeClass == .regular ? desk.cover : nil },
            set: { desk.cover = $0 }
        )
    }
}
