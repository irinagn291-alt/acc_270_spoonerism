import SwiftUI

/// Role: Onset. Twist screen for spoon-then-mend. Home also keeps the spoonered Line. Not a Game tab.
struct SpoonMendSheet: View {
    @Bindable var desk: OnsetDesk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        MarrowSheetHost {
            NavigationStack {
                Group {
                    if desk.quizIsEmpty {
                        ShelfQuiet(
                            art: MarrowArt.twistHero,
                            headline: MarrowCopy.fluentHeadline,
                            line: "Save a painting, then play.",
                            actionTitle: "Browse"
                        ) {
                            desk.present(.explore)
                        }
                    } else {
                        populated
                    }
                }
                .background(MarrowInk.background.ignoresSafeArea())
                .navigationTitle("How it works")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(MarrowType.font(.headline, size: typeSize))
                                .foregroundStyle(MarrowInk.ink)
                                .frame(minWidth: MarrowSpace.hit, minHeight: MarrowSpace.hit)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(MarrowGlyphStyle())
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MarrowSpace.gap) {
                Image(MarrowArt.twistHero)
                    .marrowCutout(maxWidth: .infinity, maxHeight: MarrowSpace.step(22))
                Text("How it works")
                    .font(MarrowType.font(.display, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .lineLimit(2)
                Text("Maker or title paints as words. Two first letters trade. Word order stays. Tap a word that swapped its first letter. A miss greys that word and keeps the rest up.")
                    .font(MarrowType.font(.body, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                if let work = desk.displayedWork {
                    VStack(alignment: .leading, spacing: MarrowSpace.inner) {
                        Text(work.title)
                            .font(MarrowType.font(.headline, size: typeSize))
                            .foregroundStyle(MarrowInk.ink)
                            .lineLimit(2)
                        Text(work.artist)
                            .font(MarrowType.font(.caption, size: typeSize))
                            .foregroundStyle(MarrowInk.muted)
                            .lineLimit(1)
                        Text(MarrowCopy.signLabel(desk.onset.sign))
                            .font(MarrowType.font(.caption, size: typeSize))
                            .foregroundStyle(MarrowInk.ink)
                    }
                    .padding(MarrowSpace.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .marrowFlat()
                }
                Button("Try a word") {
                    dismiss()
                }
                .buttonStyle(MarrowPillStyle(tone: .spoon, isLoading: false))
                .accessibilityHint("Returns to Quiz so the next word can file.")
            }
            .padding(.horizontal, MarrowSpace.outer)
            .padding(.top, MarrowSpace.card)
            .padding(.bottom, MarrowSpace.outer)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
