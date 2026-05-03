import Foundation

struct RelativeTimeFormatter {
    static func format(date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)日前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)時間前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分前"
        } else {
            return "たった今"
        }
    }
}
