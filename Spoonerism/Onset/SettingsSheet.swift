import SwiftUI

/// Role: Onset. Settings Form. Prado credit, Undo, contact URL, re-run onboarding, confirmed resetAllData. Arrives as a sheet over Quiz.
struct SettingsView: View {
    @Bindable var desk: OnsetDesk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.openURL) private var openURL
    @State private var confirmReset = false

    var body: some View {
        MarrowSheetHost {
            NavigationStack {
                Group {
                    if desk.settingsIsEmpty, desk.onsetFault != nil {
                        ShelfQuiet(
                            art: MarrowArt.emptyList,
                            headline: "Settings could not load.",
                            line: desk.onsetFault ?? MarrowCopy.writeFailed,
                            actionTitle: "Close"
                        ) {
                            dismiss()
                        }
                    } else {
                        form
                    }
                }
                .background(MarrowInk.background.ignoresSafeArea())
                .navigationTitle("Settings")
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
                .confirmationDialog(
                    "Reset all data?",
                    isPresented: $confirmReset,
                    titleVisibility: .visible
                ) {
                    Button("Reset all data", role: .destructive) {
                        Task { await desk.resetAllData() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes works, hits, and misses on this device.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var form: some View {
        Form {
            if desk.settingsIsEmpty {
                Section {
                    VStack(alignment: .leading, spacing: MarrowSpace.inner) {
                        Text("Nothing kept yet.")
                            .font(MarrowType.font(.body, size: typeSize))
                            .foregroundStyle(MarrowInk.ink)
                        Text("Save a painting, then play.")
                            .font(MarrowType.font(.caption, size: typeSize))
                            .foregroundStyle(MarrowInk.ink)
                        Button("Browse") {
                            desk.present(.explore)
                        }
                        .buttonStyle(MarrowPillStyle(tone: .spoon, isLoading: false))
                    }
                    .padding(.vertical, MarrowSpace.inner)
                    .listRowBackground(MarrowInk.surface)
                }
            }

            Section("This device") {
                countRow(title: "Works", value: desk.onset.works.count)
                countRow(title: MarrowCopy.hitsLabel, value: desk.onset.mendMarks.count)
                countRow(title: MarrowCopy.missesLabel, value: desk.onset.muffMarks.count)
                Button {
                    Task { await desk.undoNewest() }
                } label: {
                    HStack {
                        Text("Undo")
                            .font(MarrowType.font(.body, size: typeSize))
                            .foregroundStyle(MarrowInk.ink)
                        Spacer()
                        if desk.undoBusy {
                            ProgressView()
                                .tint(MarrowInk.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: MarrowSpace.hit, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MarrowRowStyle())
                .disabled(!desk.undoEnabled)
                .accessibilityHint(MarrowCopy.undoHint)
                .listRowBackground(MarrowInk.surface)
            }

            Section("Collection") {
                Button {
                    openURL(CatalogClient.pradoHomeURL)
                } label: {
                    settingsRow(title: "Museo Nacional del Prado", detail: "museodelprado.es")
                }
                .buttonStyle(MarrowRowStyle())
                .listRowBackground(MarrowInk.surface)
                Button {
                    openURL(CatalogClient.pradoEnglishURL)
                } label: {
                    settingsRow(title: "Prado English", detail: "museodelprado.es/en")
                }
                .buttonStyle(MarrowRowStyle())
                .listRowBackground(MarrowInk.surface)
                Text("Paintings hang from the Museo Nacional del Prado collection.")
                    .font(MarrowType.font(.micro, size: typeSize))
                    .foregroundStyle(MarrowInk.muted)
                    .listRowBackground(MarrowInk.surface)
            }

            Section("Support") {
                Button {
                    openURL(CatalogClient.contactURL)
                } label: {
                    settingsRow(title: "Contact", detail: "spoonerism-marrow.pro/contact-us")
                }
                .buttonStyle(MarrowRowStyle())
                .listRowBackground(MarrowInk.surface)
                Button {
                    desk.present(.spoonMend)
                } label: {
                    settingsRow(
                        title: "How it works",
                        detail: MarrowCopy.nextTap(sign: .spooned)
                    )
                }
                .buttonStyle(MarrowRowStyle())
                .listRowBackground(MarrowInk.surface)
            }

            Section {
                Button("Re-run onboarding") {
                    desk.replayOnboarding()
                }
                .font(MarrowType.font(.body, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .frame(maxWidth: .infinity, minHeight: MarrowSpace.hit, alignment: .leading)
                .contentShape(Rectangle())
                .buttonStyle(MarrowRowStyle())
                .listRowBackground(MarrowInk.surface)

                Button("Reset all data") {
                    confirmReset = true
                }
                .buttonStyle(MarrowPillStyle(tone: .wipe, isLoading: false))
                .listRowBackground(MarrowInk.background)
                .accessibilityHint("Removes works, hits, and misses after a confirm.")
            }

            if let fault = desk.onsetFault {
                Section {
                    Text(fault)
                        .font(MarrowType.font(.caption, size: typeSize))
                        .foregroundStyle(MarrowInk.ink)
                        .listRowBackground(MarrowInk.surface)
                    Button("Retry") {
                        Task { await desk.flush() }
                    }
                    .buttonStyle(MarrowPillStyle(tone: .quiet, isLoading: false))
                    .listRowBackground(MarrowInk.background)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .tint(MarrowInk.ink)
    }

    private func countRow(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(MarrowType.font(.body, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(1)
            Spacer(minLength: MarrowSpace.gap)
            Text(MarrowFigures.whole(value))
                .font(MarrowType.font(.body, size: typeSize).monospacedDigit())
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(1)
        }
        .frame(minHeight: MarrowSpace.hit)
        .listRowBackground(MarrowInk.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(MarrowFigures.whole(value))")
    }

    private func settingsRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: MarrowSpace.inner) {
            Text(title)
                .font(MarrowType.font(.body, size: typeSize))
                .foregroundStyle(MarrowInk.ink)
                .lineLimit(1)
            Text(detail)
                .font(MarrowType.font(.caption, size: typeSize))
                .foregroundStyle(MarrowInk.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: MarrowSpace.hit, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// Role: Onset. Same Settings screen. Named for the live driver key settings.
struct Settings: View {
    @Bindable var desk: OnsetDesk

    var body: some View {
        SettingsView(desk: desk)
    }
}
