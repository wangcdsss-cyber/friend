import Foundation

struct Post: Identifiable, Codable {
    var postId: String
    var authorId: String
    var gender: Gender
    var title: String
    var content: String
    var area: String
    var purpose: String
    var createdAt: Date

    var id: String { postId }
}
