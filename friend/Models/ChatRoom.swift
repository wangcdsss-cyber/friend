import Foundation

struct ChatRoom: Identifiable, Codable {
    var roomId: String
    var members: [String]
    var updatedAt: Date?
    var lastMessageAt: Date?
    var lastMessageType: MessageType?
    var lastMessageText: String?
    var lastMessageSenderId: String?
    var lastReadAtByUser: [String: Date]?

    var id: String { roomId }

    var updatedAtFallback: Date { updatedAt ?? lastMessageAt ?? Date.distantPast }
}
