import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            List(viewModel.chatRooms) { room in
                NavigationLink(destination: ChatRoomView(roomId: room.roomId)) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("チャット")
                                .font(.headline)
                            Text(room.updatedAt, style: .time)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("メッセージ")
            .onAppear {
                if let uid = authManager.currentUser?.uid {
                    viewModel.fetchChatRooms(for: uid)
                }
            }
        }
    }
}

#Preview {
    ChatListView()
}
