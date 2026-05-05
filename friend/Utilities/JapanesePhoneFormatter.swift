import Foundation

struct JapanesePhoneFormatter {
    static func formatMobile(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        if digits.count <= 3 { return digits }
        if digits.count <= 7 {
            let a = digits.prefix(3)
            let b = digits.dropFirst(3)
            return "\(a)-\(b)"
        }
        let a = digits.prefix(3)
        let b = digits.dropFirst(3).prefix(4)
        let c = digits.dropFirst(7).prefix(4)
        return "\(a)-\(b)-\(c)"
    }
}

