import SwiftUI

/// Role: Work. Explore screen. Prado shelf writes an Idle Work. Bundled shelf when query is empty or search fails. Arrives as a sheet over Quiz.
struct ExploreView: View {
    @Bindable var desk: OnsetDesk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool

    var body: some View {
        MarrowSheetHost {
            NavigationStack {
                Group {
                    if desk.exploreIsEmpty, desk.seekFault != nil {
                        errorPage
                    } else if desk.exploreIsEmpty {
                        emptyPage
                    } else {
                        populated
                    }
                }
                .background(MarrowInk.background.ignoresSafeArea())
                .navigationTitle("Browse")
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
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { searchFocused = false }
                            .font(MarrowType.font(.caption, size: typeSize))
                            .foregroundStyle(MarrowInk.ink)
                    }
                }
                .safeAreaInset(edge: .top, spacing: MarrowSpace.gap) {
                    searchField
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .task {
            if desk.seekHits.isEmpty {
                desk.scheduleSeek()
            }
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            Text("Museo Nacional del Prado")
                .font(MarrowType.font(.micro, size: typeSize))
                .foregroundStyle(MarrowInk.muted)
                .padding(.horizontal, MarrowSpace.outer)
            HStack(spacing: MarrowSpace.gap) {
                TextField("Search a work", text: $desk.query)
                    .font(MarrowType.font(.body, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onChange(of: desk.query) { _, _ in
                        desk.scheduleSeek()
                    }
                    .onSubmit {
                        searchFocused = false
                    }
                if desk.isSeeking {
                    ProgressView()
                        .tint(MarrowInk.ink)
                        .frame(width: MarrowSpace.hit, height: MarrowSpace.hit)
                }
            }
            .padding(MarrowSpace.card)
            .frame(minHeight: MarrowSpace.hit)
            .marrowFlat()
            .padding(.horizontal, MarrowSpace.outer)
            if let note = desk.shelfNote {
                Text(note)
                    .font(MarrowType.font(.micro, size: typeSize))
                    .foregroundStyle(MarrowInk.muted)
                    .padding(.horizontal, MarrowSpace.outer)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let fault = desk.seekFault, !desk.seekHits.isEmpty {
                HStack(alignment: .center, spacing: MarrowSpace.gap) {
                    Text(fault)
                        .font(MarrowType.font(.micro, size: typeSize))
                        .foregroundStyle(MarrowInk.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Retry") {
                        desk.scheduleSeek()
                    }
                    .font(MarrowType.font(.caption, size: typeSize))
                    .foregroundStyle(MarrowInk.ink)
                    .marrowHit()
                    .buttonStyle(MarrowGlyphStyle())
                    .accessibilityLabel("Retry search")
                }
                .padding(MarrowSpace.inner)
                .frame(maxWidth: .infinity, alignment: .leading)
                .marrowFlat()
                .padding(.horizontal, MarrowSpace.outer)
            }
        }
        .padding(.bottom, MarrowSpace.gap)
        .background(MarrowInk.background)
    }

    private var populated: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(desk.seekHits) { row in
                        Button {
                            searchFocused = false
                            Task { await desk.keepWork(row) }
                        } label: {
                            HStack(alignment: .center, spacing: MarrowSpace.gap) {
                                MarrowThumb(url: row.imageURL, side: MarrowSpace.step(7))
                                VStack(alignment: .leading, spacing: MarrowSpace.inner) {
                                    Text(row.title)
                                        .font(MarrowType.font(.body, size: typeSize))
                                        .foregroundStyle(MarrowInk.ink)
                                        .lineLimit(2)
                                    Text(row.artist)
                                        .font(MarrowType.font(.caption, size: typeSize))
                                        .foregroundStyle(MarrowInk.muted)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: MarrowSpace.gap)
                                rackMark(for: row)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(MarrowRowStyle())
                        .disabled(desk.stockingObjectID != nil)
                        .listRowBackground(rowBackground(for: row))
                        .listRowSeparatorTint(MarrowInk.muted.opacity(0.35))
                        .listRowInsets(
                            EdgeInsets(
                                top: MarrowSpace.gap,
                                leading: MarrowSpace.outer,
                                bottom: MarrowSpace.gap,
                                trailing: MarrowSpace.outer
                            )
                        )
                        .id(row.objectID)
                        .accessibilityLabel("\(row.title), \(row.artist)")
                        .accessibilityHint("Saves this painting on this device.")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, MarrowSpace.outer)
            .simultaneousGesture(
                TapGesture().onEnded { searchFocused = false }
            )
            .onChange(of: desk.focusedObjectID) { _, objectID in
                guard let objectID else { return }
                if reduceMotion {
                    proxy.scrollTo(objectID, anchor: .center)
                } else {
                    withAnimation(MarrowMotion.snap(reduceMotion)) {
                        proxy.scrollTo(objectID, anchor: .center)
                    }
                }
            }
        }
    }

    private func rowBackground(for row: CatalogRow) -> Color {
        if desk.focusedObjectID == row.objectID {
            return MarrowInk.accent.opacity(0.12)
        }
        return MarrowInk.surface
    }

    @ViewBuilder
    private func rackMark(for row: CatalogRow) -> some View {
        if desk.onset.works.contains(where: { $0.objectID == row.objectID }) {
            Image(systemName: "checkmark")
                .font(MarrowType.font(.caption, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .frame(width: MarrowSpace.hit, height: MarrowSpace.hit)
                .accessibilityLabel("Already saved")
        }
    }

    private var emptyPage: some View {
        ShelfQuiet(
            art: MarrowArt.emptyList,
            headline: MarrowCopy.exploreEmptyHeadline,
            line: MarrowCopy.exploreEmptyLine,
            actionTitle: "Retry"
        ) {
            desk.scheduleSeek()
        }
    }

    private var errorPage: some View {
        ShelfQuiet(
            art: MarrowArt.emptyList,
            headline: "Search could not finish.",
            line: desk.seekFault ?? MarrowCopy.seek(.transport),
            actionTitle: "Retry"
        ) {
            desk.scheduleSeek()
        }
    }
}

/// Role: Work. Same Explore screen. Named for the live driver key explore.
struct Explore: View {
    @Bindable var desk: OnsetDesk

    var body: some View {
        ExploreView(desk: desk)
    }
}
