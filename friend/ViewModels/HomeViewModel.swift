import Foundation
import Combine
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = []
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func fetchPosts(for user: AppUser) {
        listenerRegistration?.remove()
        
        let query = db.collection("posts")
            .whereField("gender", isEqualTo: user.gender.rawValue)
            .order(by: "createdAt", descending: true)
        
        listenerRegistration = query.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            self?.posts = documents.compactMap { FirestoreMapper.post(from: $0) }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}
