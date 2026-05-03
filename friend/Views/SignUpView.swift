import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedGender: Gender = .male
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                        }
                        Spacer()
                        Text("新規会員登録")
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.left").opacity(0)
                    }
                    .padding()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                labelWithIndicator("ニックネーム")
                                TextField("", text: $name, prompt: Text("表示名を入力").foregroundColor(.gray.opacity(0.6)))
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                labelWithIndicator("性別（登録後の変更はできません）")
                                HStack(spacing: 16) {
                                    genderButton(title: "男性", gender: .male)
                                    genderButton(title: "女性", gender: .female)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                labelWithIndicator("メールアドレス")
                                TextField("", text: $email, prompt: Text("メールアドレスを入力").foregroundColor(.gray.opacity(0.6)))
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                labelWithIndicator("パスワード（6文字以上）")
                                SecureField("", text: $password, prompt: Text("パスワードを入力").foregroundColor(.gray.opacity(0.6)))
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }

                            Button(action: signUp) {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("登録")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                            .cornerRadius(25)
                            .disabled(!isFormValid || isLoading)

                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6
    }

    private func labelWithIndicator(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 4, height: 18)
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .bold))
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
                .cornerRadius(25)
        }
    }

    private func signUp() {
        isLoading = true
        errorMessage = ""

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
                return
            }

            guard let uid = result?.user.uid else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            authManager.saveUser(uid: uid, name: name, gender: selectedGender) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        errorMessage = error.localizedDescription
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }
}
