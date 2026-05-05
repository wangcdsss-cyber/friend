import SwiftUI
import FirebaseAuth

struct InitialProfileSetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var name = ""
    @State private var selectedGender: Gender = .male
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("初期設定")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ニックネーム")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        TextField("", text: $name, prompt: Text("表示名を入力").foregroundColor(.gray.opacity(0.6)))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("性別（登録後の変更はできません）")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        HStack(spacing: 12) {
                            genderButton(title: "男性", gender: .male)
                            genderButton(title: "女性", gender: .female)
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(24)
                        } else {
                            Text("利用開始")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(24)
                        }
                    }
                    .disabled(isLoading || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button(action: logout) {
                        Text("ログアウト")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 6)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .onAppear {
            if let user = Auth.auth().currentUser {
                name = user.displayName ?? ""
            }
        }
    }

    private func genderButton(title: String, gender: Gender) -> some View {
        Button(action: { selectedGender = gender }) {
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedGender == gender ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                .cornerRadius(24)
        }
    }

    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = ""
        authManager.saveUser(uid: uid, name: trimmed, gender: selectedGender) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func logout() {
        authManager.signOut()
    }
}

