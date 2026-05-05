import SwiftUI

struct EmailPasswordLoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @AppStorage("auth_remember_email") private var rememberEmail = true
    @AppStorage("auth_saved_email") private var savedEmail = ""

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    @State private var showResetRequest = false
    @State private var showResetConfirm = false

    private var isValidEmail: Bool { AuthValidators.isValidEmail(email) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("メールでログイン")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

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
                            .accessibilityIdentifier("emailLogin_email")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("パスワード")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password, prompt: Text("パスワード").foregroundColor(.gray.opacity(0.6)))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("", text: $password, prompt: Text("パスワード").foregroundColor(.gray.opacity(0.6)))
                            }

                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .accessibilityIdentifier("emailLogin_password")
                    }

                    Toggle(isOn: $rememberEmail) {
                        Text("メールアドレスを保存する")
                            .foregroundColor(.white)
                    }
                    .tint(.orange)

                    Button(action: signIn) {
                        if isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(24)
                        } else {
                            Text("ログイン")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(24)
                        }
                    }
                    .accessibilityIdentifier("emailLogin_submit")
                    .disabled(isLoading || !isValidEmail || password.isEmpty)

                    Button(action: { showResetRequest = true }) {
                        Text("パスワードを忘れた方はこちら")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .accessibilityIdentifier("emailLogin_forgot")
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let code = authManager.pendingPasswordResetCode, !code.isEmpty {
                        Button(action: { showResetConfirm = true }) {
                            Text("パスワード再設定を続ける")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        .navigationDestination(isPresented: $showResetRequest) {
            PasswordResetRequestView(prefilledEmail: email)
        }
        .navigationDestination(isPresented: $showResetConfirm) {
            PasswordResetConfirmView()
        }
        .onAppear {
            if rememberEmail, !savedEmail.isEmpty {
                email = savedEmail
            }
        }
    }

    private func signIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard AuthValidators.isValidEmail(trimmedEmail) else {
            errorMessage = "メールアドレスの形式が正しくありません"
            return
        }

        isLoading = true
        errorMessage = ""
        authManager.signInWithEmail(email: trimmedEmail, password: password) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                    return
                }
                if rememberEmail {
                    savedEmail = trimmedEmail
                } else {
                    savedEmail = ""
                }
            }
        }
    }
}
