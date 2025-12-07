import Foundation

enum BusDayType: String, CaseIterable, Identifiable {
    case weekday = "平日"
    case saturday = "土曜日"
    case holiday = "日・祝日"
    var id: String { rawValue }
}

enum BusTimetable {
    static let hours: [Int] = Array(7...22)

    // Format: [dayType: [hour: [minutes]]]
    static let toCampus: [BusDayType: [Int: [Int]]] = [
        .weekday: [
            7: [30, 40, 45],
            8: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45],
            9: [5, 15, 25, 35, 55],
            10: [5, 15, 25, 30, 35],
            11: [25, 45, 55],
            12: [45, 55],
            13: [5, 10, 40],
            14: [5, 15, 30, 40, 45, 55],
            15: [5, 15, 30, 40, 45, 55],
            16: [20, 50],
            17: [10, 15, 20, 30, 40],
        ],
        .saturday: [
            7: [30, 40],
            8: [0, 5, 10, 15, 20, 25, 30, 35, 40],
            9: [30, 55],
            10: [25, 35, 55],
            11: [25, 40, 55],
            12: [45, 55],
            13: [0, 5, 15, 20, 25],
            14: [20, 35, 50],
            15: [20, 30, 50],
            16: [20],
        ],
        .holiday: [
            12: [25],
            13: [45],
        ]
    ]

    static let fromCampus: [BusDayType: [Int: [Int]]] = [
        .weekday: [
            7: [5, 10, 15, 20, 25, 30, 35],
            8: [0, 20, 30, 45, 50],
            9: [5, 35, 45, 55],
            10: [5, 15, 20, 25],
            11: [15, 40],
            12: [35, 45, 50, 55],
            13: [0, 30],
            14: [5, 10, 40],
            15: [5, 20, 25, 30, 35, 40, 45],
            16: [10, 40],
            17: [0, 5, 10, 20, 30, 45, 55],
            18: [0, 20, 30, 35],
            19: [0, 35, 45],
            20: [45],
            21: [15],
            22: [0],
        ],
        .saturday: [
            7: [5, 10, 15, 20, 25, 30, 35],
            8: [0, 10, 20, 40],
            9: [20, 45],
            10: [15, 25, 45],
            11: [15, 30, 45],
            12: [35, 45, 50, 55],
            13: [5, 10, 15, 35],
            14: [10, 40],
            15: [10, 25, 40],
            16: [10, 40],
            17: [10, 40],
            18: [10, 40],
            19: [10, 30],
        ],
        .holiday: [
            12: [15],
            13: [35],
        ]
    ]

    static func dayType(for date: Date = Date()) -> BusDayType {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date) // 1=Sun ... 7=Sat
        if weekday == 1 { return .holiday }
        if weekday == 7 { return .saturday }
        return .weekday
    }

    // Returns next departure hour and minute for a mode at the given date
    static func nextDeparture(for mode: CommuteMode, from date: Date = Date()) -> (hour: Int, minute: Int)? {
        let day = dayType(for: date)
        let dict = (mode == .toSchool) ? toCampus[day] ?? [:] : fromCampus[day] ?? [:]
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)

        // Search current hour
        if let mins = dict[h] {
            if let next = mins.first(where: { $0 >= m }) {
                return (h, next)
            }
        }
        // Search following hours
        for hour in (h+1)...22 {
            if let mins = dict[hour], let first = mins.first {
                return (hour, first)
            }
        }
        // No more buses today
        return nil
    }

    // Returns the next departure; if none left today, returns the first bus of the next day.
    static func nextDepartureRolling(for mode: CommuteMode, from date: Date = Date()) -> (hour: Int, minute: Int, isNextDay: Bool)? {
        if let nd = nextDeparture(for: mode, from: date) {
            return (nd.hour, nd.minute, false)
        }
        // Move to next day at 00:00 local
        let cal = Calendar.current
        guard let nextDay = cal.date(byAdding: .day, value: 1, to: date),
              let startOfNext = cal.startOfDay(for: nextDay) as Date? else { return nil }
        let day = dayType(for: nextDay)
        let dict = (mode == .toSchool) ? toCampus[day] ?? [:] : fromCampus[day] ?? [:]
        // Find earliest hour with times
        let hoursSorted = dict.keys.sorted()
        guard let firstHour = hoursSorted.first, let mins = dict[firstHour], let firstMin = mins.sorted().first else {
            return nil
        }
        return (firstHour, firstMin, true)
    }
}
