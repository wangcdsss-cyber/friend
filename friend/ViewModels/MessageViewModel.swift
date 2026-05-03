import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class MessageViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private let roomId: String
    
    init(roomId: String) {
        self.roomId = roomId
    }
    
    func fetchMessages() {
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("chatRooms").document(roomId).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.messages = documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }
            }
    }
    
    func sendMessage(text: String, senderId: String) {
        let roomRef = db.collection("chatRooms").document(roomId)
        let messageRef = roomRef.collection("messages").document()
        let newMessage = Message(
            messageId: messageRef.documentID,
            senderId: senderId,
            text: text,
            createdAt: Date()
        )
        
        do {
            try messageRef.setData(from: newMessage)
            roomRef.updateData([
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
