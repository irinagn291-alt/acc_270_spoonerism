import SwiftUI

/// Role: Line. Spoonered Line under the Quiz tile. Spoon and mend fuse here. Seats stay. First letters trade.
struct LineView: View {
    @Bindable var desk: OnsetDesk
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            if case .spooned(let line) = desk.onset.hanging {
                liveLine(line)
            } else if let line = desk.onset.line {
                settledLine(line)
            } else {
                idleCue
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func liveLine(_ line: Line) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            fieldChip(line.field)
            VStack(alignment: .leading, spacing: MarrowSpace.gap) {
                ForEach(line.heads) { head in
                    seatButton(head)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func seatButton(_ head: Head) -> some View {
        HeadButton(
            head: head,
            phase: phase(head),
            isBusy: desk.mendBusy == head.id,
            isArmed: true
        ) {
            Task { await desk.mend(head.id) }
        }
    }

    private func settledLine(_ line: Line) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            fieldChip(line.field)
            VStack(alignment: .leading, spacing: MarrowSpace.gap) {
                ForEach(line.heads) { head in
                    seatedReadout(head)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(line.heads.map(\.spoken).joined(separator: " "))
        }
    }

    private var idleCue: some View {
        Text("Maker or title will paint as words.")
            .font(MarrowType.font(.body, size: typeSize))
            .foregroundStyle(MarrowInk.ink)
            .frame(maxWidth: .infinity, minHeight: MarrowSpace.hit, alignment: .leading)
            .padding(.horizontal, MarrowSpace.card)
            .marrowFlat()
    }

    private func fieldChip(_ field: LineField) -> some View {
        Text(MarrowCopy.fieldLabel(field))
            .font(MarrowType.font(.title, size: typeSize))
            .foregroundStyle(MarrowInk.ink)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Field, \(MarrowCopy.fieldLabel(field))")
    }

    private func seatedReadout(_ head: Head) -> some View {
        Text(head.spoken)
            .font(MarrowType.font(.body, size: typeSize))
            .strikethrough(head.isGrey, color: MarrowInk.ink)
            .foregroundStyle(head.isGrey ? MarrowInk.muted : MarrowInk.ink)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
    }

    private func phase(_ head: Head) -> HeadPhase {
        if head.isGrey { return .muffed }
        if head.isRighted { return .righted }
        if case .spooned(let line) = desk.onset.hanging, line.isSwapped(head.id) {
            return .swapped
        }
        return .open
    }
}

/// Role: Line. Wraps seated Heads onto the remaining width. Identity stays on Head.id.
struct HeadFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let plan = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, origin) in plan.origins.enumerated() {
            guard subviews.indices.contains(index), plan.sizes.indices.contains(index) else { continue }
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(plan.sizes[index])
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint], sizes: [CGSize]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        var origins: [CGPoint] = []
        var sizes: [CGSize] = []
        for sub in subviews {
            let ideal = sub.sizeThatFits(.unspecified)
            let size: CGSize
            if maxWidth.isFinite, ideal.width > maxWidth {
                size = sub.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            } else {
                size = ideal
            }
            if x > 0, maxWidth.isFinite, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            sizes.append(size)
            maxX = max(maxX, x + size.width)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        let width = maxWidth.isFinite ? maxWidth : maxX
        return (CGSize(width: width, height: y + rowHeight), origins, sizes)
    }
}
