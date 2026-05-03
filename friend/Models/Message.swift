import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum MessageType: String, Codable {
    case text
    case image
}

struct Message: Identifiable, Codable {
    var messageId: String
    var senderId: String
    var type: MessageType
    var text: String?
    var imageUrl: String?
    var imageWidth: Double?
    var imageHeight: Double?
    @ServerTimestamp var createdAt: Date?
    var clientCreatedAt: Date

    var id: String { messageId }

    var createdAtFallback: Date { createdAt ?? clientCreatedAt }
}
