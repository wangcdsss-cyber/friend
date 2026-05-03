import SwiftUI
import FirebaseFirestore

struct ChatRoomView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: MessageViewModel
    @State private var newMessageText = ""
    @State private var showingActionSheet = false
    @State private var showingReportAlert = false
    
    let roomId: String
    
    init(roomId: String) {
        self.roomId = roomId
        self._viewModel = StateObject(wrappedValue: MessageViewModel(roomId: roomId))
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isFromCurrentUser: message.senderId == authManager.currentUser?.uid)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessageId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            HStack {
                TextField("メッセージを入力...", text: $newMessageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("チャット")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .confirmationDialog("ユーザーへの操作", isPresented: $showingActionSheet) {
            Button("通報する", role: .destructive) { showingReportAlert = true }
            Button("このユーザーをブロック", role: .destructive) { blockUser() }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("通報しますか？", isPresented: $showingReportAlert) {
            Button("通報", role: .destructive) { reportUser() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("不適切なユーザーとして運営に通報します。")
        }
        .onAppear {
            viewModel.fetchMessages()
        }
    }
    
    private func reportUser() {
        // Implement reporting logic
    }
    
    private func blockUser() {
        // Implement blocking logic
    }
    
    private func sendMessage() {
        guard let currentUid = authManager.currentUser?.uid else { return }
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.sendMessage(text: text, senderId: currentUid)
        newMessageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(isFromCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}
