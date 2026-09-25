import SwiftUI

/// Role: MendMark. Recent rail plus one MuffMark count. Uneven 2 plus 1. Flat fill. Not a second hero.
struct MendMarkRail: View {
    @Bindable var desk: OnsetDesk
    var columnWidth: CGFloat
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let gap = MarrowSpace.gap
        let statWidth = max((columnWidth - gap) / 3, MarrowSpace.hit)
        let railWidth = max(columnWidth - gap - statWidth, MarrowSpace.hit)
        HStack(alignment: .top, spacing: gap) {
            recentRail
                .frame(width: railWidth, alignment: .topLeading)
            muffStat
                .frame(width: statWidth, alignment: .topLeading)
        }
        .frame(width: columnWidth, alignment: .leading)
    }

    private var recentRail: some View {
        VStack(alignment: .leading, spacing: MarrowSpace.gap) {
            Text(MarrowCopy.recentHits)
                .font(MarrowType.font(.caption, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if desk.onset.reviewableMends.isEmpty {
                Text("None yet")
                    .font(MarrowType.font(.body, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .frame(maxWidth: .infinity, minHeight: MarrowSpace.hit, alignment: .leading)
                    .padding(.horizontal, MarrowSpace.card)
                    .marrowFlat()
            } else {
                ForEach(desk.onset.reviewableMends.reversed()) { mark in
                    chip(mark)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ mark: MendMark) -> some View {
        let work = desk.work(for: mark)
        let title = work?.title ?? "Work"
        return Button {
            desk.present(.saved)
        } label: {
            HStack(alignment: .center, spacing: MarrowSpace.inner) {
                MarrowThumb(url: work?.imageURL, side: MarrowSpace.step(7))
                VStack(alignment: .leading, spacing: MarrowSpace.inner) {
                    Text(mark.opening)
                        .font(MarrowType.font(.headline, size: typeSize).monospacedDigit())
                        .foregroundStyle(MarrowInk.ink)
                        .lineLimit(1)
                    Text(title)
                        .font(MarrowType.font(.body, size: typeSize))
                        .foregroundStyle(MarrowInk.ink)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(MarrowFigures.daykey(mark.daykey))
                        .font(MarrowType.font(.caption, size: typeSize).monospacedDigit())
                        .foregroundStyle(MarrowInk.ink)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(MarrowSpace.inner)
            .frame(maxWidth: .infinity, alignment: .leading)
            .marrowFlat(MarrowRadius.chip)
            .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.chip, style: .continuous))
        }
        .buttonStyle(MarrowRowStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Hit \(mark.opening), \(title), \(MarrowFigures.daykey(mark.daykey))"
        )
    }

    private var muffStat: some View {
        Button {
            desk.present(.saved)
        } label: {
            VStack(alignment: .leading, spacing: MarrowSpace.inner) {
                Text(MarrowCopy.missesLabel)
                    .font(MarrowType.font(.caption, size: typeSize))
                    .foregroundStyle(MarrowInk.muted)
                    .lineLimit(1)
                Text(MarrowFigures.whole(desk.onset.reviewableMuffs.count))
                    .font(MarrowType.font(.title, size: typeSize).monospacedDigit())
                    .foregroundStyle(MarrowInk.ink)
                    .lineLimit(1)
                Text("kept")
                    .font(MarrowType.font(.caption, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .lineLimit(1)
            }
            .padding(MarrowSpace.card)
            .frame(maxWidth: .infinity, minHeight: MarrowSpace.hit, alignment: .leading)
            .marrowFlat()
            .contentShape(RoundedRectangle(cornerRadius: MarrowRadius.card, style: .continuous))
        }
        .buttonStyle(MarrowRowStyle())
        .accessibilityLabel(missVoice)
        .accessibilityHint("Opens kept paintings.")
    }

    private var missVoice: String {
        let count = MarrowFigures.whole(desk.onset.reviewableMuffs.count)
        return "\(count) misses kept"
    }
}
