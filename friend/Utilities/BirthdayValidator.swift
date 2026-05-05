import Foundation

struct BirthdayValidator {
    static func age(on date: Date, birthday: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.year], from: birthday, to: date)
        guard let years = components.year else { return 0 }
        let birthdayThisYear = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: calendar.date(byAdding: .year, value: years, to: birthday) ?? birthday) ?? birthday
        if date < birthdayThisYear {
            return max(0, years - 1)
        }
        return max(0, years)
    }

    static func isAllowedAge(birthday: Date, now: Date = Date(), calendar: Calendar = .current, min: Int = 18, max: Int = 80) -> Bool {
        let a = age(on: now, birthday: birthday, calendar: calendar)
        return a >= min && a <= max
    }
}

