import SwiftUI
import Combine
import FirebaseAuth

struct PhoneLoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationId: String?

    @State private var isSending = false
    @State private var isSigningIn = false
    @State private var countdown = 0
    @State private var errorMessage = ""

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var e164: String? { AuthValidators.normalizedJapaneseE164(from: phoneNumber) }
    private var canSendCode: Bool { e164 != nil && !isSending && countdown == 0 }
    private var canSignIn: Bool { verificationId != nil && verificationCode.count >= 6 && !isSigningIn }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("携帯番号でログイン")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text("日本の携帯番号（070/080/090）に対応しています。例：09012345678")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("携帯番号")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("", text: $phoneNumber, prompt: Text("09012345678").foregroundColor(.gray.opacity(0.6)))
                            .keyboardType(.phonePad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .accessibilityIdentifier("phoneLogin_phone")
                    }

                    HStack(spacing: 10) {
                        Button(action: sendCode) {
                            if isSending {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(20)
                            } else {
                                Text(countdown > 0 ? "再送信 \(countdown)s" : "送信验证码")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(20)
                            }
                        }
                        .accessibilityIdentifier("phoneLogin_sendCode")
                        .disabled(!canSendCode)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("验证码")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("", text: $verificationCode, prompt: Text("6桁").foregroundColor(.gray.opacity(0.6)))
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .disabled(verificationId == nil)
                            .opacity(verificationId == nil ? 0.4 : 1)
                            .accessibilityIdentifier("phoneLogin_code")
                    }

                    Button(action: signIn) {
                        if isSigningIn {
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
                    .accessibilityIdentifier("phoneLogin_submit")
                    .disabled(!canSignIn)

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
        .onReceive(ticker) { _ in
            if countdown > 0 {
                countdown -= 1
            }
        }
    }

    private func sendCode() {
        guard let e164 else {
            errorMessage = "携帯番号の形式が正しくありません"
            return
        }

        isSending = true
        errorMessage = ""
        PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { verificationId, error in
            DispatchQueue.main.async {
                isSending = false
                if let error {
                    errorMessage = error.localizedDescription
                    return
                }
                self.verificationId = verificationId
                countdown = 60
            }
        }
    }

    private func signIn() {
        guard let verificationId else { return }
        let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count >= 6 else { return }

        isSigningIn = true
        errorMessage = ""
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)
        Auth.auth().signIn(with: credential) { _, error in
            DispatchQueue.main.async {
                isSigningIn = false
                if let error {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
