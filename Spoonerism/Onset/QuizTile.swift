import SwiftUI
import UIKit

/// Role: Onset. Photography-first Quiz tile. Soft shadow only here. Caption lives under the tile, not on it.
struct QuizTile: View {
    let work: Work?
    let showSuccess: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var mark: CGFloat = 56
    @State private var photo: Image?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            tile
            if showSuccess {
                Image(MarrowArt.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: mark, height: mark)
                    .padding(MarrowSpace.card)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: MarrowRadius.card, style: .continuous))
        .shadow(
            color: MarrowLift.shade,
            radius: MarrowLift.shadeRadius,
            y: MarrowLift.shadeY
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(work.map { "\($0.title), \($0.artist)" } ?? "Painting tile")
        .animation(MarrowMotion.snap(reduceMotion), value: showSuccess)
        .task(id: work?.imageURL) {
            await loadPhoto()
        }
    }

    private var tile: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                ZStack {
                    MarrowInk.surface
                    if let photo {
                        photo
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .clipped()
    }

    private func loadPhoto() async {
        photo = nil
        guard let url = work?.imageURL else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled else { return }
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else { return }
            guard let image = UIImage(data: data) else { return }
            photo = Image(uiImage: image)
        } catch {
            photo = nil
        }
    }
}
