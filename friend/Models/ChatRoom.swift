import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatRoom: Identifiable, Codable {
    var roomId: String
    var members: [String]
    @ServerTimestamp var updatedAt: Date?
    @ServerTimestamp var lastMessageAt: Date?
    var lastMessageType: MessageType?
    var lastMessageText: String?
    var lastMessageSenderId: String?
    var lastReadAtByUser: [String: Date]?

    var id: String { roomId }

    var updatedAtFallback: Date { updatedAt ?? lastMessageAt ?? Date.distantPast }
}
