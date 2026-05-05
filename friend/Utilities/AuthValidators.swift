import Foundation

struct AuthValidators {
    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 254 { return false }
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    static func normalizedJapaneseE164(from input: String) -> String? {
        let digits = input.filter(\.isNumber)
        if digits.isEmpty { return nil }

        if input.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("+") {
            if digits.hasPrefix("81") {
                let rest = String(digits.dropFirst(2))
                if isValidJapaneseNational(rest) {
                    return "+81\(rest)"
                }
            }
            return nil
        }

        if digits.hasPrefix("0") {
            let national = String(digits.dropFirst())
            if isValidJapaneseNational(national) {
                return "+81\(national)"
            }
            return nil
        }

        if digits.hasPrefix("81") {
            let rest = String(digits.dropFirst(2))
            if isValidJapaneseNational(rest) {
                return "+81\(rest)"
            }
        }

        return nil
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8 && password.count <= 32
    }

    private static func isValidJapaneseNational(_ national: String) -> Bool {
        guard national.count == 10 else { return false }
        let prefixes = ["70", "80", "90"]
        return prefixes.contains(where: { national.hasPrefix($0) })
    }
}
