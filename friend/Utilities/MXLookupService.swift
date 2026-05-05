import Foundation

struct MXLookupService {
    struct Result {
        let hasMX: Bool
        let errorMessage: String?
    }

    static func checkMX(domain: String) async -> Result {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Result(hasMX: false, errorMessage: "ドメインが空です") }

        guard let url = URL(string: "https://dns.google/resolve?name=\(trimmed)&type=MX") else {
            return Result(hasMX: false, errorMessage: "URL生成に失敗しました")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return Result(hasMX: false, errorMessage: "DNS問い合わせに失敗しました")
            }

            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let answer = obj?["Answer"] as? [[String: Any]]
            let has = (answer?.isEmpty == false)
            return Result(hasMX: has, errorMessage: has ? nil : "MXレコードが見つかりません")
        } catch {
            return Result(hasMX: false, errorMessage: "DNS問い合わせに失敗しました")
        }
    }
}

