import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthManager: ObservableObject {
    enum SessionState: Equatable {
        case checking
        case signedOut
        case signedInNeedsProfile
        case signedInReady
    }

    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var pendingPasswordResetCode: String?
    @Published var sessionState: SessionState = .checking
    
    private let db = Firestore.firestore()
    
    init() {
        // Listen to Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self else { return }
            if let user = user {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    self.sessionState = .signedInNeedsProfile
                }
                self.fetchUser(uid: user.uid)
                return
            }

            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
                self.sessionState = .signedOut
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
                    self?.sessionState = .signedInReady
                }
            } else {
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.sessionState = .signedInNeedsProfile
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

    func signInWithEmail(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            completion(error)
        }
    }

    func sendPasswordResetEmail(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            completion(error)
        }
    }

    func handleIncomingAuthLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let items = components.queryItems ?? []
        let mode = items.first(where: { $0.name == "mode" })?.value
        let oobCode = items.first(where: { $0.name == "oobCode" })?.value
        if mode == "resetPassword", let oobCode, !oobCode.isEmpty {
            DispatchQueue.main.async {
                self.pendingPasswordResetCode = oobCode
            }
        }
    }

    func verifyPasswordResetCode(_ oobCode: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().verifyPasswordResetCode(oobCode) { email, error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(email ?? ""))
        }
    }

    func confirmPasswordReset(oobCode: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().confirmPasswordReset(withCode: oobCode, newPassword: newPassword) { error in
            completion(error)
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
