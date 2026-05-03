import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("プロフィール情報")) {
                    HStack {
                        Text("ニックネーム")
                        Spacer()
                        Text(authManager.currentUser?.name ?? "未設定")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("性別")
                        Spacer()
                        Text({
                            guard let gender = authManager.currentUser?.gender else { return "未設定" }
                            return gender == .male ? "男性" : "女性"
                        }())
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        authManager.signOut()
                    }) {
                        Text("ログアウト")
                    }
                }
            }
            .navigationTitle("マイページ")
        }
    }
}

#Preview {
    ProfileView()
}
