import Foundation
import UIKit
import Combine
import FirebaseFirestore
import FirebaseStorage

class MessageViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var room: ChatRoom?
    @Published var otherUser: AppUser?
    @Published var uploadProgressByMessageId: [String: Double] = [:]
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listenerRegistration: ListenerRegistration?
    private var roomListenerRegistration: ListenerRegistration?
    private let roomId: String
    private var currentUid: String?
    private var localMessages: [String: Message] = [:]
    private var pendingImages: [String: UIImage] = [:]
    private var sendingMessageIds: Set<String> = []
    private var failedMessageIds: Set<String> = []
    
    init(roomId: String) {
        self.roomId = roomId
    }
    
    func start(currentUid: String) {
        if self.currentUid == currentUid { return }
        self.currentUid = currentUid
        listenRoom(currentUid: currentUid)
        listenMessages()
        markRoomAsRead(currentUid: currentUid)
    }

    func listenMessages() {
        listenerRegistration?.remove()

        listenerRegistration = db.collection("chatRooms").document(roomId).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "获取消息失败：\(error.localizedDescription)"
                    return
                }
                guard let self else { return }
                guard let documents = snapshot?.documents else { return }

                let remoteMessages = documents.compactMap { FirestoreMapper.message(from: $0) }
                var merged: [Message] = remoteMessages

                let remoteIds = Set(remoteMessages.map { $0.messageId })
                for (id, local) in self.localMessages where !remoteIds.contains(id) {
                    merged.append(local)
                }

                merged.sort(by: { $0.createdAtFallback < $1.createdAtFallback })
                self.messages = merged
            }
    }

    func pendingImage(for messageId: String) -> UIImage? {
        pendingImages[messageId]
    }

    func sendText(_ text: String) {
        guard let currentUid else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let roomRef = db.collection("chatRooms").document(roomId)
        let messageRef = roomRef.collection("messages").document()
        let messageId = messageRef.documentID

        let local = Message(
            messageId: messageId,
            senderId: currentUid,
            type: .text,
            text: trimmed,
            imageUrl: nil,
            imageWidth: nil,
            imageHeight: nil,
            createdAt: nil,
            clientCreatedAt: Date()
        )

        localMessages[messageId] = local
        sendingMessageIds.insert(messageId)
        failedMessageIds.remove(messageId)

        let batch = db.batch()
        batch.setData(FirestoreMapper.messageData(local, createdAt: FieldValue.serverTimestamp()), forDocument: messageRef)
        batch.setData([
            "roomId": roomId,
            "updatedAt": FieldValue.serverTimestamp(),
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastMessageType": MessageType.text.rawValue,
            "lastMessageText": trimmed,
            "lastMessageSenderId": currentUid,
            "lastReadAtByUser.\(currentUid)": FieldValue.serverTimestamp()
        ], forDocument: roomRef, merge: true)

        batch.commit { [weak self] error in
            guard let self else { return }
            if let error {
                self.failedMessageIds.insert(messageId)
                self.errorMessage = "发送失败：\(error.localizedDescription)"
            } else {
                self.sendingMessageIds.remove(messageId)
                self.localMessages.removeValue(forKey: messageId)
            }
        }
    }

    func sendImage(_ image: UIImage) {
        guard let currentUid else { return }
        guard let members = room?.members, members.count >= 2 else {
            errorMessage = "无法发送图片：未获取到房间成员信息"
            return
        }

        guard let data = ImageCompressor.jpegData(from: image) else {
            errorMessage = "图片压缩失败"
            return
        }

        let sorted = members.sorted()
        let uidA = sorted[0]
        let uidB = sorted[1]

        let roomRef = db.collection("chatRooms").document(roomId)
        let messageRef = roomRef.collection("messages").document()
        let messageId = messageRef.documentID

        let local = Message(
            messageId: messageId,
            senderId: currentUid,
            type: .image,
            text: nil,
            imageUrl: nil,
            imageWidth: image.size.width,
            imageHeight: image.size.height,
            createdAt: nil,
            clientCreatedAt: Date()
        )

        localMessages[messageId] = local
        pendingImages[messageId] = image
        uploadProgressByMessageId[messageId] = 0
        sendingMessageIds.insert(messageId)
        failedMessageIds.remove(messageId)

        let path = "chatImages/\(uidA)/\(uidB)/\(messageId).jpg"
        let ref = storage.reference(withPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let task = ref.putData(data, metadata: metadata)
        task.observe(.progress) { [weak self] snapshot in
            guard let self else { return }
            let fraction = snapshot.progress?.fractionCompleted ?? 0
            DispatchQueue.main.async {
                self.uploadProgressByMessageId[messageId] = fraction
            }
        }
        task.observe(.failure) { [weak self] snapshot in
            guard let self else { return }
            DispatchQueue.main.async {
                self.failedMessageIds.insert(messageId)
                self.errorMessage = snapshot.error?.localizedDescription ?? "图片上传失败"
            }
        }
        task.observe(.success) { [weak self] _ in
            guard let self else { return }
            ref.downloadURL { url, error in
                if let error {
                    DispatchQueue.main.async {
                        self.failedMessageIds.insert(messageId)
                        self.errorMessage = "获取图片地址失败：\(error.localizedDescription)"
                    }
                    return
                }
                guard let url else {
                    DispatchQueue.main.async {
                        self.failedMessageIds.insert(messageId)
                        self.errorMessage = "获取图片地址失败"
                    }
                    return
                }

                let finalized = Message(
                    messageId: messageId,
                    senderId: currentUid,
                    type: .image,
                    text: nil,
                    imageUrl: url.absoluteString,
                    imageWidth: image.size.width,
                    imageHeight: image.size.height,
                    createdAt: nil,
                    clientCreatedAt: local.clientCreatedAt
                )

                let batch = self.db.batch()
                batch.setData(FirestoreMapper.messageData(finalized, createdAt: FieldValue.serverTimestamp()), forDocument: messageRef)
                batch.setData([
                    "roomId": self.roomId,
                    "updatedAt": FieldValue.serverTimestamp(),
                    "lastMessageAt": FieldValue.serverTimestamp(),
                    "lastMessageType": MessageType.image.rawValue,
                    "lastMessageText": "",
                    "lastMessageSenderId": currentUid,
                    "lastReadAtByUser.\(currentUid)": FieldValue.serverTimestamp()
                ], forDocument: roomRef, merge: true)

                batch.commit { [weak self] error in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        if let error {
                            self.failedMessageIds.insert(messageId)
                            self.errorMessage = "发送图片失败：\(error.localizedDescription)"
                        } else {
                            self.sendingMessageIds.remove(messageId)
                            self.localMessages.removeValue(forKey: messageId)
                            self.pendingImages.removeValue(forKey: messageId)
                            self.uploadProgressByMessageId.removeValue(forKey: messageId)
                        }
                    }
                }
            }
        }
    }

    func sendTestImage() {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 64, y: 64, width: 384, height: 384))
            let text = "UI TEST"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.black
            ]
            let textSize = text.size(withAttributes: attributes)
            let origin = CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2)
            text.draw(at: origin, withAttributes: attributes)
        }
        sendImage(image)
    }

    func statusText(for message: Message) -> String? {
        guard let currentUid else { return nil }
        let otherUid = room?.members.first(where: { $0 != currentUid })
        let status = MessageStatusCalculator.status(
            currentUid: currentUid,
            messageSenderId: message.senderId,
            messageTime: message.createdAtFallback,
            otherUid: otherUid,
            otherReadAt: otherUid.flatMap { room?.lastReadAtByUser?[$0] },
            isSending: sendingMessageIds.contains(message.messageId),
            isFailed: failedMessageIds.contains(message.messageId)
        )
        return status?.displayText
    }

    private func listenRoom(currentUid: String) {
        roomListenerRegistration?.remove()
        let roomRef = db.collection("chatRooms").document(roomId)
        roomListenerRegistration = roomRef.addSnapshotListener { [weak self] snapshot, error in
            if let error {
                self?.errorMessage = "获取房间信息失败：\(error.localizedDescription)"
                return
            }
            guard let self else { return }
            guard let snapshot else { return }
            if let room = FirestoreMapper.chatRoom(from: snapshot) {
                self.room = room
                let otherUid = room.members.first(where: { $0 != currentUid })
                if let otherUid {
                    self.fetchOtherUserIfNeeded(uid: otherUid)
                }
            }
        }
    }

    private func fetchOtherUserIfNeeded(uid: String) {
        if otherUser?.uid == uid { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error {
                self?.errorMessage = "获取用户信息失败：\(error.localizedDescription)"
                return
            }
            guard let snapshot else { return }
            if let user = FirestoreMapper.appUser(from: snapshot) {
                DispatchQueue.main.async {
                    self?.otherUser = user
                }
            }
        }
    }

    private func markRoomAsRead(currentUid: String) {
        db.collection("chatRooms").document(roomId).updateData([
            "lastReadAtByUser.\(currentUid)": FieldValue.serverTimestamp()
        ])
    }
    
    deinit {
        listenerRegistration?.remove()
        roomListenerRegistration?.remove()
    }
}
