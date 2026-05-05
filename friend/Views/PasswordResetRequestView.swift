import SwiftUI

struct PasswordResetRequestView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email: String
    @State private var isLoading = false
    @State private var message = ""
    @State private var errorMessage = ""
    @State private var showResetConfirm = false

    init(prefilledEmail: String) {
        _email = State(initialValue: prefilledEmail)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("パスワード再設定")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("登録したメールアドレス宛に再設定リンクを送信します。")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 8) {
                    Text("メールアドレス")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    TextField("", text: $email, prompt: Text("メールアドレス").foregroundColor(.gray.opacity(0.6)))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }

                Button(action: send) {
                    if isLoading {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(24)
                    } else {
                        Text("送信")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(24)
                    }
                }
                .disabled(isLoading || !AuthValidators.isValidEmail(email))

                Button(action: { showResetConfirm = true }) {
                    Text("既にメールを受け取った方（コード入力）")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .navigationDestination(isPresented: $showResetConfirm) {
            PasswordResetConfirmView()
        }
    }

    private func send() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard AuthValidators.isValidEmail(trimmedEmail) else {
            errorMessage = "メールアドレスの形式が正しくありません"
            return
        }

        isLoading = true
        message = ""
        errorMessage = ""
        authManager.sendPasswordResetEmail(email: trimmedEmail) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    message = "再設定メールを送信しました。メール内のリンクから新しいパスワードを設定してください。"
                }
            }
        }
    }
}
