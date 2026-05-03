import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    
    private let db = Firestore.firestore()
    
    init() {
        // Listen to Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if let user = user {
                self?.fetchUser(uid: user.uid)
            } else {
                self?.isAuthenticated = false
                self?.currentUser = nil
            }
        }
    }
    
    func fetchUser(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }
            
            if let data = snapshot?.data(),
               let uid = data["uid"] as? String,
               let genderString = data["gender"] as? String,
               let gender = Gender(rawValue: genderString),
               let name = data["name"] as? String,
               let profileImageUrl = data["profileImageUrl"] as? String,
               let bio = data["bio"] as? String {
                
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                let user = AppUser(
                    uid: uid,
                    name: name,
                    gender: gender,
                    profileImageUrl: profileImageUrl,
                    bio: bio,
                    createdAt: createdAt
                )
                    
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                }
            } else {
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func saveUser(uid: String, name: String, gender: Gender, profileImageUrl: String = "", bio: String = "", completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = [
            "uid": uid,
            "name": name,
            "gender": gender.rawValue,
            "profileImageUrl": profileImageUrl,
            "bio": bio,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            completion(error)
            if error == nil {
                self.fetchUser(uid: uid)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
