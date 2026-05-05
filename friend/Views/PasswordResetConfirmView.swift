import SwiftUI

struct PasswordResetConfirmView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var oobCode = ""
    @State private var emailForReset = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var didVerifyCode = false

    private var canVerify: Bool { !oobCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var canConfirm: Bool { didVerifyCode && newPassword.count >= 6 && newPassword == confirmPassword }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("新しいパスワード設定")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    if !emailForReset.isEmpty {
                        Text("対象メール: \(emailForReset)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("確認コード（メールリンクの oobCode）")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        TextField("", text: $oobCode, prompt: Text("コード").foregroundColor(.gray.opacity(0.6)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }

                    Button(action: verify) {
                        if isLoading && !didVerifyCode {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(24)
                        } else {
                            Text("コード確認")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(24)
                        }
                    }
                    .disabled(isLoading || !canVerify || didVerifyCode)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("新しいパスワード（6文字以上）")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        SecureField("", text: $newPassword, prompt: Text("新しいパスワード").foregroundColor(.gray.opacity(0.6)))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .opacity(didVerifyCode ? 1 : 0.4)
                    .disabled(!didVerifyCode)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("新しいパスワード（確認）")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        SecureField("", text: $confirmPassword, prompt: Text("もう一度入力").foregroundColor(.gray.opacity(0.6)))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .opacity(didVerifyCode ? 1 : 0.4)
                    .disabled(!didVerifyCode)

                    Button(action: confirm) {
                        if isLoading && didVerifyCode {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(24)
                        } else {
                            Text("パスワードを更新")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(24)
                        }
                    }
                    .disabled(isLoading || !canConfirm)

                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer().frame(height: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .onAppear {
            if let pending = authManager.pendingPasswordResetCode, !pending.isEmpty {
                oobCode = pending
            }
        }
    }

    private func verify() {
        let trimmed = oobCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = ""
        successMessage = ""
        authManager.verifyPasswordResetCode(trimmed) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let email):
                    didVerifyCode = true
                    emailForReset = email
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func confirm() {
        let trimmed = oobCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard didVerifyCode else { return }
        guard newPassword == confirmPassword, newPassword.count >= 6 else { return }

        isLoading = true
        errorMessage = ""
        successMessage = ""
        authManager.confirmPasswordReset(oobCode: trimmed, newPassword: newPassword) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                    return
                }
                successMessage = "パスワードを更新しました。ログインしてください。"
                authManager.pendingPasswordResetCode = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                    dismiss()
                })
            }
        }
    }
}
