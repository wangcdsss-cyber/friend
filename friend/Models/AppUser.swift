import Foundation

enum Gender: String, Codable {
    case male = "male"
    case female = "female"
}

struct AppUser: Identifiable, Codable {
    var uid: String
    var name: String
    var gender: Gender
    var profileImageUrl: String
    var bio: String
    var createdAt: Date

    var id: String { uid }
}
