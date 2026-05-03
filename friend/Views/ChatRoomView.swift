import SwiftUI
import UIKit
import FirebaseFirestore

struct ChatRoomView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: MessageViewModel
    @State private var newMessageText = ""
    @State private var showingActionSheet = false
    @State private var showingReportAlert = false
    @State private var showingMediaPicker = false
    @State private var showingImagePicker = false
    @State private var pickerSource: ImagePicker.Source = .photoLibrary
    
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
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authManager.currentUser?.uid,
                                pendingImage: viewModel.pendingImage(for: message.messageId),
                                statusText: viewModel.statusText(for: message),
                                uploadProgress: viewModel.uploadProgressByMessageId[message.messageId]
                            )
                                .accessibilityIdentifier(message.type == .image ? "imageBubble_\(message.messageId)" : "textBubble_\(message.messageId)")
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .accessibilityIdentifier("messageScroll")
                .scrollIndicators(.hidden)
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
                Button(action: { showingMediaPicker = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("mediaButton")

                TextField("输入消息...", text: $newMessageText)
                    .padding(10)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                    .tint(.white)
                    .accessibilityIdentifier("messageInput")
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("sendButton")
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(viewModel.otherUser?.name ?? "聊天")
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
        .confirmationDialog("发送图片", isPresented: $showingMediaPicker) {
            Button("拍照") {
                pickerSource = .camera
                showingImagePicker = true
            }
            Button("从相册选择") {
                pickerSource = .photoLibrary
                showingImagePicker = true
            }
            if ProcessInfo.processInfo.arguments.contains("-ui_testing") {
                Button("发送测试图片") {
                    viewModel.sendTestImage()
                }
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(source: pickerSource) { image in
                viewModel.sendImage(image)
            }
            .ignoresSafeArea()
        }
        .alert("通報しますか？", isPresented: $showingReportAlert) {
            Button("通報", role: .destructive) { reportUser() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("不適切なユーザーとして運営に通報します。")
        }
        .alert("提示", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            if let uid = authManager.currentUser?.uid {
                viewModel.start(currentUid: uid)
            }
        }
    }
    
    private func reportUser() {
        // Implement reporting logic
    }
    
    private func blockUser() {
        // Implement blocking logic
    }
    
    private func sendMessage() {
        let text = newMessageText
        viewModel.sendText(text)
        newMessageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let pendingImage: UIImage?
    let statusText: String?
    let uploadProgress: Double?
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 6) {
                messageContent
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color.white.opacity(0.12))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 260, alignment: isFromCurrentUser ? .trailing : .leading)

                HStack(spacing: 8) {
                    Text(message.createdAtFallback, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                    if let statusText, isFromCurrentUser {
                        Text(statusText)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }

            if !isFromCurrentUser { Spacer() }
        }
    }

    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .text:
            Text(message.text ?? "")
                .font(.system(size: 16))
                .fixedSize(horizontal: false, vertical: true)
        case .image:
            ZStack {
                if let pendingImage {
                    Image(uiImage: pendingImage)
                        .resizable()
                        .scaledToFill()
                } else if let urlString = message.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color.white.opacity(0.08)
                        }
                    }
                } else {
                    Color.white.opacity(0.08)
                }

                if let uploadProgress, uploadProgress < 1 {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.35))
                        .cornerRadius(10)
                        .padding(10)
                }
            }
            .frame(width: 200, height: 240)
            .clipped()
            .cornerRadius(12)
        }
    }
}
