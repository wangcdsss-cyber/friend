import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Message: Identifiable, Codable {
    var messageId: String
    var senderId: String
    var text: String
    var createdAt: Date

    var id: String { messageId }
}
