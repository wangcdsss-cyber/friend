import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            List(viewModel.conversations) { conversation in
                NavigationLink(destination: ChatRoomView(roomId: conversation.room.roomId)) {
                    ConversationRowView(conversation: conversation)
                }
                .accessibilityIdentifier("conversationRow_\(conversation.id)")
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .accessibilityIdentifier("chatList")
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("メッセージ")
            .refreshable {
                if let uid = authManager.currentUser?.uid {
                    await viewModel.refresh(for: uid)
                }
            }
            .onAppear {
                if let uid = authManager.currentUser?.uid {
                    viewModel.fetchChatRooms(for: uid)
                }
            }
        }
    }
}

private struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: conversation.otherUser?.profileImageUrl)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(conversation.otherUser?.name ?? "ユーザー")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(conversation.lastPreviewText.isEmpty ? " " : conversation.lastPreviewText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(RelativeTimeFormatter.format(date: conversation.lastTimestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))

                if conversation.hasUnread {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                } else {
                    Color.clear.frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}

private struct AvatarView: View {
    let urlString: String?

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.08))
            if let urlString, let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .contentShape(Circle())
    }
}

#Preview {
    ChatListView()
}
