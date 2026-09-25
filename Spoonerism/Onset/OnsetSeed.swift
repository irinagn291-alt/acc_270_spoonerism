import Foundation

/// Role: Onset. Simulator demo crate. Device never writes this. Key: spn.demo.v1. Paints a live Line so the first Head can mend. Never Fluent.
enum OnsetSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func onset(
        now: Date = Date(),
        calendar: Calendar = .current,
        picker: any FieldPicking = FixedFieldPicker(field: .title),
        pairing: any HeadPairing = FirstLastPairing(),
        shelf: [CatalogRow] = Shelf.bundled.rows
    ) -> Onset {
        let today = Daykey.stamp(now, calendar: calendar)
        let rows = shelf
        func work(_ row: CatalogRow, id: UUID, fold: WorkFold, dayOffset: Int) -> Work {
            var item = Work.idle(from: row, id: id, daykey: Daykey.shifting(today, by: dayOffset, calendar: calendar))
            item.fold = fold
            return item
        }

        let meninas = work(rows[0], id: fixed("AAAAAAAA-0001-4000-8000-000000000001"), fold: .spooned, dayOffset: 0)
        let thirdMay = work(rows[1], id: fixed("AAAAAAAA-0001-4000-8000-000000000002"), fold: .mended, dayOffset: -1)
        let garden = work(rows[2], id: fixed("AAAAAAAA-0001-4000-8000-000000000003"), fold: .mended, dayOffset: -2)
        let breda = work(rows[3], id: fixed("AAAAAAAA-0001-4000-8000-000000000004"), fold: .idle, dayOffset: -3)
        let saturn = work(rows[4], id: fixed("AAAAAAAA-0001-4000-8000-000000000005"), fold: .idle, dayOffset: -4)
        let maja = work(rows[5], id: fixed("AAAAAAAA-0001-4000-8000-000000000006"), fold: .mended, dayOffset: -5)
        let nobleman = work(rows[6], id: fixed("AAAAAAAA-0001-4000-8000-000000000007"), fold: .idle, dayOffset: -6)
        let descent = work(rows[7], id: fixed("AAAAAAAA-0001-4000-8000-000000000008"), fold: .idle, dayOffset: -7)

        let works = [meninas, thirdMay, garden, breda, saturn, maja, nobleman, descent]
        let live = (try? LinePress.make(
            work: meninas,
            field: picker.field(for: meninas),
            pairing: pairing,
            headIDs: [
                fixed("EEEEEEEE-0001-4000-8000-000000000001"),
                fixed("EEEEEEEE-0001-4000-8000-000000000002"),
                fixed("EEEEEEEE-0001-4000-8000-000000000003"),
                fixed("EEEEEEEE-0001-4000-8000-000000000004"),
                fixed("EEEEEEEE-0001-4000-8000-000000000005"),
                fixed("EEEEEEEE-0001-4000-8000-000000000006"),
                fixed("EEEEEEEE-0001-4000-8000-000000000007"),
                fixed("EEEEEEEE-0001-4000-8000-000000000008"),
            ]
        )) ?? Line(
            workID: meninas.id,
            field: .title,
            heads: [],
            leftID: fixed("EEEEEEEE-0001-4000-8000-000000000001"),
            rightID: fixed("EEEEEEEE-0001-4000-8000-000000000002")
        )

        let thirdLine = (try? LinePress.make(
            work: thirdMay,
            field: .title,
            pairing: pairing
        )) ?? live
        let gardenLine = (try? LinePress.make(
            work: garden,
            field: .title,
            pairing: pairing
        )) ?? live
        let majaLine = (try? LinePress.make(
            work: maja,
            field: .title,
            pairing: pairing
        )) ?? live

        let mendMarks = [
            MendMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000001"),
                workID: thirdMay.id,
                field: .title,
                headID: thirdLine.leftID,
                seat: 0,
                opening: thirdLine.head(id: thirdLine.leftID)?.nativeOpening ?? "T",
                daykey: thirdMay.daykey
            ),
            MendMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000002"),
                workID: garden.id,
                field: .title,
                headID: gardenLine.leftID,
                seat: 0,
                opening: gardenLine.head(id: gardenLine.leftID)?.nativeOpening ?? "T",
                daykey: garden.daykey
            ),
            MendMark(
                id: fixed("BBBBBBBB-0001-4000-8000-000000000003"),
                workID: maja.id,
                field: .title,
                headID: majaLine.rightID,
                seat: majaLine.head(id: majaLine.rightID)?.seat ?? 1,
                opening: majaLine.head(id: majaLine.rightID)?.nativeOpening ?? "M",
                daykey: maja.daykey
            ),
        ]
        let muffMarks = [
            MuffMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000001"),
                workID: thirdMay.id,
                field: .title,
                headID: fixed("FFFFFFFF-0001-4000-8000-000000000001"),
                seat: 1,
                spoken: "Third",
                daykey: thirdMay.daykey
            ),
            MuffMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000002"),
                workID: garden.id,
                field: .title,
                headID: fixed("FFFFFFFF-0001-4000-8000-000000000002"),
                seat: 2,
                spoken: "of",
                daykey: garden.daykey
            ),
            MuffMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000003"),
                workID: maja.id,
                field: .title,
                headID: fixed("FFFFFFFF-0001-4000-8000-000000000003"),
                seat: 1,
                spoken: "Nude",
                daykey: maja.daykey
            ),
            MuffMark(
                id: fixed("DDDDDDDD-0001-4000-8000-000000000004"),
                workID: breda.id,
                field: .title,
                headID: fixed("FFFFFFFF-0001-4000-8000-000000000004"),
                seat: 1,
                spoken: "Surrender",
                daykey: breda.daykey
            ),
        ]
        return Onset(
            schemaVersion: Onset.currentSchema,
            onboardingComplete: true,
            works: works,
            hanging: .spooned(live),
            mendMarks: mendMarks,
            muffMarks: muffMarks,
            peelLog: [],
            cachedRows: Array(rows.prefix(8)),
            focusedWorkID: meninas.id
        )
    }
}
