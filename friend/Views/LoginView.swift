import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showingSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 40)
                    
                    // Identifier Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メールアドレス")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        TextField("", text: $email, prompt: Text("メールアドレスを入力").foregroundColor(.gray.opacity(0.6)))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("パスワード（数字6桁以上）")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password, prompt: Text("パスワードを入力").foregroundColor(.gray.opacity(0.6)))
                            } else {
                                SecureField("", text: $password, prompt: Text("パスワードを入力").foregroundColor(.gray.opacity(0.6)))
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
                    }
                    
                    // Login Button
                    Button(action: {
                        signIn()
                    }) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(25)
                        } else {
                            Text("ログイン")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(25)
                        }
                    }
                    .padding(.top, 8)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    
                    // Forgot Password
                    Button(action: { sendPasswordReset() }) {
                        Text("パスワードを忘れてしまった場合")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 8)
                    
                    // New Registration
                    Button(action: {
                        showingSignUp = true
                    }) {
                        Text("新規会員登録")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(25)
                    }
                    
                    // Previous Users
                    Button(action: {}) {
                        Text("以前会員登録した方はこちら")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func sendPasswordReset() {
        guard !email.isEmpty else {
            errorMessage = "メールアドレスを入力してください"
            return
        }
        errorMessage = ""
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    errorMessage = "パスワード再設定メールを送信しました"
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
