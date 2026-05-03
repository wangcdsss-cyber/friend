import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    // Form States
    @State private var comment = ""
    @State private var selectedDuration: DurationOption = .oneDay
    @State private var selectedPrefectures: [String] = []
    
    // UI States
    @State private var showingDurationPicker = false
    @State private var showingPrefecturePicker = false
    @State private var showingConfirmationModal = false
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
    private let maxCommentLength = 500
    private let maxPrefectureCount = 5
    
    enum DurationOption: String, CaseIterable, Identifiable {
        case threeHours = "3時間"
        case oneDay = "1日"
        case oneWeek = "一週間"
        case oneMonth = "1ヶ月"
        
        var id: String { self.rawValue }
        
        var seconds: TimeInterval {
            switch self {
            case .threeHours: return 10800
            case .oneDay: return 86400
            case .oneWeek: return 604800
            case .oneMonth: return 2592000
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: {
                            hideKeyboard()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingConfirmationModal = true
                            }
                        }) {
                            Text("投稿内容を確認")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isFormValid ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                                .foregroundColor(isFormValid ? .white : .gray)
                                .cornerRadius(20)
                        }
                        .disabled(!isFormValid || isSubmitting)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            
                            // 1. 募集条件
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader("募集条件")
                                
                                // Duration Selector
                                selectionRow(title: "募集期間", value: selectedDuration.rawValue, isRequired: true) {
                                    showingDurationPicker = true
                                }
                                
                                // Prefecture Selector
                                selectionRow(title: "地域", value: selectedPrefectures.isEmpty ? nil : selectedPrefectures.joined(separator: ", "), isRequired: true) {
                                    showingPrefecturePicker = true
                                }
                            }
                            
                            // 2. 募集内容
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader("募集内容", isRequired: true)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    TextEditor(text: $comment)
                                        .frame(height: 250)
                                        .scrollContentBackground(.hidden) // Hide default white background
                                        .padding(12)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .onChange(of: comment) { _, newValue in
                                            if newValue.count > maxCommentLength {
                                                comment = String(newValue.prefix(maxCommentLength))
                                            }
                                        }
                                    
                                    Text("\(comment.count)/\(maxCommentLength)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(12)
                                }
                            }
                            
                            // 注意事項
                            VStack(alignment: .leading, spacing: 8) {
                                Text("【注意事項】")
                                Text("※アイコンがご自身が写った写真に設定していない場合、投稿を削除いたします。")
                                Text("※募集期間を過ぎたものは削除されます。")
                                Text("※宣伝、ネットワークビジネス、パーティー業者と見受けられるものは禁止となっています。見つけ次第、削除退会処置をとります。")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            
                            Spacer().frame(height: 40)
                        }
                        .padding(.horizontal, 16)
                    }
                    .opacity(showingConfirmationModal ? 0 : 1) // Smoothly fade out the form
                }
                
                // Overlay Pickers
                if showingDurationPicker {
                    DurationPicker(selectedOption: $selectedDuration, isPresented: $showingDurationPicker)
                }
                
                if showingPrefecturePicker {
                    PrefecturePicker(selectedPrefectures: $selectedPrefectures, isPresented: $showingPrefecturePicker, errorMessage: $errorMessage, maxCount: maxPrefectureCount)
                }
                
                // Confirmation Modal
                if showingConfirmationModal {
                    ConfirmationModal(
                        isPresented: $showingConfirmationModal,
                        duration: selectedDuration,
                        prefectures: selectedPrefectures,
                        comment: comment,
                        isSubmitting: isSubmitting,
                        errorMessage: errorMessage,
                        onPost: submitPost
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(1)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var isFormValid: Bool {
        !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedPrefectures.isEmpty
    }
    
    private func sectionHeader(_ title: String, isRequired: Bool = false) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4, height: 18)
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
            if isRequired {
                Text("必須")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
        }
    }
    
    private func selectionRow(title: String, value: String?, isRequired: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                if isRequired && value == nil {
                    Text("必須")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                Spacer()
                if let value = value {
                    Text(value)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func submitPost() {
        guard let user = authManager.currentUser else { return }
        isSubmitting = true
        errorMessage = ""
        
        let db = Firestore.firestore()
        let now = Date()
        let docRef = db.collection("posts").document()
        
        let newPost = Post(
            postId: docRef.documentID,
            authorId: user.uid,
            gender: user.gender,
            title: comment.prefix(20).description,
            content: comment,
            area: selectedPrefectures.joined(separator: ", "),
            purpose: "募集",
            createdAt: now
        )
        
        do {
            try docRef.setData(from: newPost) { error in
                isSubmitting = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    showingConfirmationModal = false
                    dismiss()
                }
            }
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Confirmation Modal
struct ConfirmationModal: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isPresented: Bool
    let duration: CreatePostView.DurationOption
    let prefectures: [String]
    let comment: String
    let isSubmitting: Bool
    let errorMessage: String
    let onPost: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    Spacer()
                    
                    Text("募集期間:  \(duration.rawValue)")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Preview Card
                VStack(alignment: .leading, spacing: 16) {
                    if let user = authManager.currentUser {
                        HStack(alignment: .top, spacing: 12) {
                            AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                                    .overlay(Text(user.name.prefix(1)).foregroundColor(.white))
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(user.gender == .male ? "男性" : "女性")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                
                                if !user.bio.isEmpty {
                                    Text(user.bio)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prefectures.joined(separator: ", "))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("#楽しく飲みたい #友達増やしたい #わりと酒豪") // Dummy tags matching reference
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Text(comment)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Text("この内容で投稿しますか？")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Final Post Button
                Button(action: onPost) {
                    if isSubmitting {
                        ProgressView().tint(.black)
                    } else {
                        Text("投稿")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(25)
                .padding(.horizontal, 24)
                .disabled(isSubmitting)
                
                Spacer().frame(height: 20)
            }
            .padding(.top, 40)
            .background(Color(hex: "121212"))
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

// Corner rounding utility
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Duration Picker View
struct DurationPicker: View {
    @Binding var selectedOption: CreatePostView.DurationOption
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { isPresented = false }
            
            VStack(spacing: 0) {
                Text("募集期間")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                Divider().background(Color.gray)
                
                ForEach(CreatePostView.DurationOption.allCases) { option in
                    Button(action: {
                        selectedOption = option
                    }) {
                        HStack {
                            Image(systemName: selectedOption == option ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedOption == option ? .blue : .gray)
                            Text(option.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                    }
                }
                
                Divider().background(Color.gray)
                
                HStack {
                    Button("キャンセル") { isPresented = false }
                        .foregroundColor(.blue)
                    Spacer()
                    Button("OK") { isPresented = false }
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
            .frame(maxWidth: 300)
        }
    }
}

// MARK: - Prefecture Picker View
struct PrefecturePicker: View {
    @Binding var selectedPrefectures: [String]
    @Binding var isPresented: Bool
    @Binding var errorMessage: String
    let maxCount: Int
    
    @State private var searchText = ""
    
    let prefectures = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県",
        "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県",
        "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県",
        "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
    
    var filteredPrefectures: [String] {
        if searchText.isEmpty { return prefectures }
        return prefectures.filter { $0.contains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { isPresented = false }
            
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("地域")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("最大\(maxCount)つまで選択可能です")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                
                TextField("", text: $searchText, prompt: Text("検索...").foregroundColor(.white.opacity(0.7)))
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .foregroundColor(.white)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPrefectures, id: \.self) { pref in
                            Button(action: {
                                if selectedPrefectures.contains(pref) {
                                    selectedPrefectures.removeAll { $0 == pref }
                                } else if selectedPrefectures.count < maxCount {
                                    selectedPrefectures.append(pref)
                                } else {
                                    // 5つ選択済みの状態で他を選ぼうとした場合
                                    errorMessage = "地域は最大\(maxCount)箇所まで選択可能です"
                                    // 2秒後にメッセージを消す
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        errorMessage = ""
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedPrefectures.contains(pref) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedPrefectures.contains(pref) ? .blue : .gray)
                                    Text(pref)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
                
                Divider().background(Color.gray)
                
                HStack {
                    Button("キャンセル") { isPresented = false }
                        .foregroundColor(.blue)
                    Spacer()
                    Button("OK") { isPresented = false }
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .background(Color(hex: "1C1C1E"))
            .cornerRadius(16)
            .frame(maxWidth: 320)
        }
    }
}
