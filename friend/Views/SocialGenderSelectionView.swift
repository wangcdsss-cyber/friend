import SwiftUI
import FirebaseAuth

struct SocialGenderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var name = ""
    @State private var selectedGender: Gender = .male
    @State private var acceptedEULA = false
    @State private var showingEULADetails = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("プロフィール設定"), footer: Text("ソーシャルログイン後の初期設定です。")) {
                    TextField("ニックネーム", text: $name)
                    
                    Picker("性別", selection: $selectedGender) {
                        Text("男性").tag(Gender.male)
                        Text("女性").tag(Gender.female)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("利用規約")) {
                    Toggle(isOn: $acceptedEULA) {
                        HStack {
                            Text("利用規約(EULA)に同意する")
                            Button(action: { showingEULADetails = true }) {
                                Text("詳細を確認")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Button(action: completeRegistration) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("利用開始")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading || name.isEmpty || !acceptedEULA)
            }
            .navigationTitle("初期設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEULADetails) {
                EULADetailView(isPresented: $showingEULADetails)
            }
        }
        .onAppear {
            // Pre-fill name if available from Firebase Auth
            if let user = Auth.auth().currentUser {
                self.name = user.displayName ?? ""
            }
        }
    }
    
    private func completeRegistration() {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        
        authManager.saveUser(
            uid: user.uid,
            name: name,
            gender: selectedGender
        ) { error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                authManager.isAuthenticated = true
                dismiss()
            }
        }
    }
}

struct EULADetailView: View {
    @Binding var isPresented: Bool
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("""
                    【利用規約 (EULA)】
                    当アプリをご利用いただくには、以下の規約に同意いただく必要があります。
                    
                    1. 不適切なコンテンツの禁止
                    嫌がらせ、差別、性的な内容、過度な暴力など、他者が不快に感じるコンテンツの投稿を禁止します。
                    
                    2. 迷惑行為の禁止
                    他ユーザーへの誹謗中傷や、スパム行為を禁止します。
                    
                    3. 違反への対応
                    規約に違反した場合、運営の判断により投稿の削除やアカウントの停止措置を行うことがあります。
                    
                    4. ブロック・通報機能の利用
                    不快なユーザーやコンテンツを見つけた場合は、アプリ内のブロック・通報機能を利用してください。
                    """)
                    .padding()
            }
            .navigationTitle("利用規約")
            .toolbar {
                Button("閉じる") { isPresented = false }
            }
        }
    }
}
