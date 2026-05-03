import Foundation

enum OutgoingMessageStatus: String {
    case sending
    case sent
    case read
    case failed

    var displayText: String {
        switch self {
        case .sending: return "发送中"
        case .sent: return "已发送"
        case .read: return "已读"
        case .failed: return "发送失败"
        }
    }
}

struct MessageStatusCalculator {
    static func status(currentUid: String,
                       messageSenderId: String,
                       messageTime: Date,
                       otherUid: String?,
                       otherReadAt: Date?,
                       isSending: Bool,
                       isFailed: Bool) -> OutgoingMessageStatus? {
        guard messageSenderId == currentUid else { return nil }
        if isFailed { return .failed }
        if isSending { return .sending }
        guard let otherUid else { return .sent }
        let readAt = otherReadAt ?? Date.distantPast
        return readAt >= messageTime ? .read : .sent
    }
}

