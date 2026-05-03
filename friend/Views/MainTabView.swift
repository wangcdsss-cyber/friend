import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(authManager)
                .tabItem {
                    Label("掲示板", systemImage: "list.bullet.clipboard")
                }
            
            ChatListView()
                .environmentObject(authManager)
                .tabItem {
                    Label("メッセージ", systemImage: "message.fill")
                }
            
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Label("マイページ", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    MainTabView()
}
