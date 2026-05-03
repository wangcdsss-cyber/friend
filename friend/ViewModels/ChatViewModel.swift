import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Conversation: Identifiable {
    let room: ChatRoom
    let otherUser: AppUser?
    let currentUid: String

    var id: String { room.roomId }

    var otherUid: String? {
        room.members.first(where: { $0 != currentUid })
    }

    var lastPreviewText: String {
        switch room.lastMessageType {
        case .image:
            return "图片"
        case .text:
            return room.lastMessageText?.isEmpty == false ? (room.lastMessageText ?? "") : ""
        case nil:
            return ""
        }
    }

    var lastTimestamp: Date {
        room.lastMessageAt ?? room.updatedAtFallback
    }

    var hasUnread: Bool {
        let lastMessageAt = room.lastMessageAt ?? room.updatedAt
        guard let lastMessageAt else { return false }
        let lastReadAt = room.lastReadAtByUser?[currentUid]
        return (lastReadAt ?? Date.distantPast) < lastMessageAt
    }
}

class ChatViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var conversations: [Conversation] = []
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var userCache: [String: AppUser] = [:]
    private var inFlightUserFetch: Set<String> = []
    
    func fetchChatRooms(for uid: String) {
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("chatRooms")
            .whereField("members", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching chat rooms: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let rooms = documents.compactMap { doc -> ChatRoom? in
                    try? doc.data(as: ChatRoom.self)
                }
                self?.chatRooms = rooms.sorted(by: { $0.updatedAtFallback > $1.updatedAtFallback })
                self?.fetchOtherUsersIfNeeded(currentUid: uid, rooms: rooms)
                self?.rebuildConversations(currentUid: uid, rooms: rooms)
            }
    }
    
    func createOrGetRoom(currentUid: String, targetUid: String, completion: @escaping (String?) -> Void) {
        let sorted = [currentUid, targetUid].sorted()
        let uidA = sorted[0]
        let uidB = sorted[1]
        let roomId = "\(uidA)_\(uidB)"
        let docRef = db.collection("chatRooms").document(roomId)

        docRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error getting chat room: \(error)")
                completion(nil)
                return
            }
            if snapshot?.exists == true {
                completion(roomId)
                return
            }

            let newRoom = ChatRoom(
                roomId: roomId,
                members: [uidA, uidB],
                updatedAt: nil,
                lastMessageAt: nil,
                lastMessageType: nil,
                lastMessageText: nil,
                lastMessageSenderId: nil,
                lastReadAtByUser: [currentUid: Date()]
            )

            do {
                try docRef.setData(from: newRoom) { err in
                    if let err {
                        print("Error creating chat room: \(err)")
                        completion(nil)
                        return
                    }
                    self?.fetchOtherUsersIfNeeded(currentUid: currentUid, rooms: [newRoom])
                    completion(roomId)
                }
            } catch {
                print("Error creating chat room: \(error)")
                completion(nil)
            }
        }
    }

    func refresh(for uid: String) async {
        do {
            let snapshot = try await db.collection("chatRooms")
                .whereField("members", arrayContains: uid)
                .order(by: "updatedAt", descending: true)
                .getDocuments()
            let rooms = snapshot.documents.compactMap { try? $0.data(as: ChatRoom.self) }
            await MainActor.run {
                self.chatRooms = rooms.sorted(by: { $0.updatedAtFallback > $1.updatedAtFallback })
                self.fetchOtherUsersIfNeeded(currentUid: uid, rooms: rooms)
                self.rebuildConversations(currentUid: uid, rooms: rooms)
            }
        } catch {
            print("Error refreshing chat rooms: \(error)")
        }
    }

    private func rebuildConversations(currentUid: String, rooms: [ChatRoom]) {
        conversations = rooms.map { room in
            let otherUid = room.members.first(where: { $0 != currentUid })
            return Conversation(room: room, otherUser: otherUid.flatMap { userCache[$0] }, currentUid: currentUid)
        }
    }

    private func fetchOtherUsersIfNeeded(currentUid: String, rooms: [ChatRoom]) {
        let otherUids = Set(rooms.compactMap { $0.members.first(where: { $0 != currentUid }) })
        for uid in otherUids {
            if userCache[uid] != nil { continue }
            if inFlightUserFetch.contains(uid) { continue }
            inFlightUserFetch.insert(uid)
            db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
                defer { self?.inFlightUserFetch.remove(uid) }
                if let error {
                    print("Error fetching user: \(error)")
                    return
                }
                guard let snapshot else { return }
                if let user = try? snapshot.data(as: AppUser.self) {
                    self?.userCache[uid] = user
                    DispatchQueue.main.async {
                        self?.rebuildConversations(currentUid: currentUid, rooms: self?.chatRooms ?? rooms)
                    }
                }
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
