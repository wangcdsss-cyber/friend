import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatRoom: Identifiable, Codable {
    var roomId: String
    var members: [String]
    var updatedAt: Date

    var id: String { roomId }
}
