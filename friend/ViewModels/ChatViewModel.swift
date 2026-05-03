import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class ChatViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
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
                
                self?.chatRooms = documents.compactMap { doc -> ChatRoom? in
                    try? doc.data(as: ChatRoom.self)
                }
            }
    }
    
    func createOrGetRoom(currentUid: String, targetUid: String, completion: @escaping (String?) -> Void) {
        db.collection("chatRooms")
            .whereField("members", arrayContains: currentUid)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error checking existing rooms: \(error)")
                    completion(nil)
                    return
                }
                
                if let existingRoom = snapshot?.documents.first(where: { doc in
                    if let room = try? doc.data(as: ChatRoom.self) {
                        return room.members.contains(targetUid)
                    }
                    return false
                }) {
                    completion(existingRoom.documentID)
                    return
                }
                
                guard let self else { completion(nil); return }
                let docRef = self.db.collection("chatRooms").document()
                let newRoom = ChatRoom(
                    roomId: docRef.documentID,
                    members: [currentUid, targetUid],
                    updatedAt: Date()
                )
                
                do {
                    try docRef.setData(from: newRoom) { error in
                        if let error = error {
                            print("Error creating chat room: \(error)")
                            completion(nil)
                        } else {
                            completion(docRef.documentID)
                        }
                    }
                } catch {
                    print("Error creating chat room: \(error)")
                    completion(nil)
                }
            }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
