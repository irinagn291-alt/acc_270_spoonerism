import Foundation

/// Role: Onset. Daykey as Int YYYYMMDD from Calendar.startOfDay in the current zone.
enum Daykey {
    static func stamp(_ date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return year * 10_000 + month * 100 + day
    }

    static func shifting(_ daykey: Int, by days: Int, calendar: Calendar) -> Int {
        var parts = DateComponents()
        parts.year = daykey / 10_000
        parts.month = (daykey / 100) % 100
        parts.day = daykey % 100
        let base = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        let moved = calendar.date(byAdding: .day, value: days, to: base) ?? base
        return stamp(moved, calendar: calendar)
    }
}
