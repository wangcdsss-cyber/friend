import Foundation
import FirebaseFirestore

struct FirestoreMapper {
    static func appUser(from snapshot: DocumentSnapshot) -> AppUser? {
        guard let data = snapshot.data() else { return nil }
        return appUser(from: data, documentId: snapshot.documentID)
    }

    static func appUser(from data: [String: Any], documentId: String) -> AppUser? {
        let uid = (data["uid"] as? String) ?? documentId
        guard let genderString = data["gender"] as? String,
              let gender = Gender(rawValue: genderString)
        else { return nil }

        let name = (data["name"] as? String) ?? (data["nickname"] as? String) ?? ""
        let profileImageUrl = (data["profileImageUrl"] as? String) ?? ""
        let bio = (data["bio"] as? String) ?? ""
        let createdAt = date(from: data["createdAt"]) ?? Date()

        return AppUser(
            uid: uid,
            name: name,
            gender: gender,
            profileImageUrl: profileImageUrl,
            bio: bio,
            createdAt: createdAt
        )
    }

    static func post(from snapshot: QueryDocumentSnapshot) -> Post? {
        let data = snapshot.data()
        let postId = (data["postId"] as? String) ?? snapshot.documentID
        guard let authorId = data["authorId"] as? String else { return nil }
        guard let genderString = data["gender"] as? String, let gender = Gender(rawValue: genderString) else { return nil }
        guard let title = data["title"] as? String else { return nil }
        guard let content = data["content"] as? String else { return nil }
        guard let area = data["area"] as? String else { return nil }
        guard let purpose = data["purpose"] as? String else { return nil }
        let createdAt = date(from: data["createdAt"]) ?? Date()

        return Post(
            postId: postId,
            authorId: authorId,
            gender: gender,
            title: title,
            content: content,
            area: area,
            purpose: purpose,
            createdAt: createdAt
        )
    }

    static func chatRoom(from snapshot: DocumentSnapshot) -> ChatRoom? {
        guard let data = snapshot.data() else { return nil }
        let roomId = (data["roomId"] as? String) ?? snapshot.documentID
        let members = (data["members"] as? [String]) ?? []

        let updatedAt = date(from: data["updatedAt"])
        let lastMessageAt = date(from: data["lastMessageAt"])

        let lastMessageType = (data["lastMessageType"] as? String).flatMap { MessageType(rawValue: $0) }
        let lastMessageText = data["lastMessageText"] as? String
        let lastMessageSenderId = data["lastMessageSenderId"] as? String

        var lastReadAtByUser: [String: Date] = [:]
        if let map = data["lastReadAtByUser"] as? [String: Any] {
            for (k, v) in map {
                if let d = date(from: v) {
                    lastReadAtByUser[k] = d
                }
            }
        }

        return ChatRoom(
            roomId: roomId,
            members: members,
            updatedAt: updatedAt,
            lastMessageAt: lastMessageAt,
            lastMessageType: lastMessageType,
            lastMessageText: lastMessageText,
            lastMessageSenderId: lastMessageSenderId,
            lastReadAtByUser: lastReadAtByUser.isEmpty ? nil : lastReadAtByUser
        )
    }

    static func message(from snapshot: QueryDocumentSnapshot) -> Message? {
        let data = snapshot.data()
        let messageId = (data["messageId"] as? String) ?? snapshot.documentID
        guard let senderId = data["senderId"] as? String else { return nil }
        guard let typeString = data["type"] as? String, let type = MessageType(rawValue: typeString) else { return nil }

        let text = data["text"] as? String
        let imageUrl = data["imageUrl"] as? String
        let imageWidth = data["imageWidth"] as? Double
        let imageHeight = data["imageHeight"] as? Double
        let createdAt = date(from: data["createdAt"])
        let clientCreatedAt = date(from: data["clientCreatedAt"]) ?? Date()

        return Message(
            messageId: messageId,
            senderId: senderId,
            type: type,
            text: text,
            imageUrl: imageUrl,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            createdAt: createdAt,
            clientCreatedAt: clientCreatedAt
        )
    }

    static func messageData(_ message: Message, createdAt: Any) -> [String: Any] {
        var data: [String: Any] = [
            "messageId": message.messageId,
            "senderId": message.senderId,
            "type": message.type.rawValue,
            "createdAt": createdAt,
            "clientCreatedAt": Timestamp(date: message.clientCreatedAt)
        ]
        if let text = message.text { data["text"] = text }
        if let imageUrl = message.imageUrl { data["imageUrl"] = imageUrl }
        if let w = message.imageWidth { data["imageWidth"] = w }
        if let h = message.imageHeight { data["imageHeight"] = h }
        return data
    }

    static func postData(_ post: Post) -> [String: Any] {
        [
            "postId": post.postId,
            "authorId": post.authorId,
            "gender": post.gender.rawValue,
            "title": post.title,
            "content": post.content,
            "area": post.area,
            "purpose": post.purpose,
            "createdAt": Timestamp(date: post.createdAt)
        ]
    }

    private static func date(from value: Any?) -> Date? {
        if let ts = value as? Timestamp { return ts.dateValue() }
        if let d = value as? Date { return d }
        return nil
    }
}

