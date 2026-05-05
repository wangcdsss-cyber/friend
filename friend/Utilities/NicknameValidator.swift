import Foundation

struct NicknameValidator {
    static func sanitized(_ input: String) -> String {
        input.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }

    static func isValid(_ input: String) -> Bool {
        let s = sanitized(input)
        if s.count < 2 || s.count > 20 { return false }
        return s.allSatisfy { isAllowedCharacter($0) }
    }

    private static func isAllowedCharacter(_ ch: Character) -> Bool {
        if ch.isEmoji { return true }
        for scalar in ch.unicodeScalars {
            if CharacterSet.punctuationCharacters.contains(scalar) { return false }
            if CharacterSet.symbols.contains(scalar) { return false }
        }
        return true
    }
}

private extension Character {
    var isEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji }
    }
}

