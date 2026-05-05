import SwiftUI

struct RegistrationMethodSelectionView: View {
    @State private var showEmailRegistration = false
    @State private var showPhoneRegistration = false

    @State private var showTerms = false
    @State private var agreed = false
    @State private var selectedProvider: Provider?

    private enum Provider {
        case email
        case phone
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("新規会員登録")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("登録方法を選択してください。")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Button(action: {
                    selectedProvider = .email
                    agreed = false
                    showTerms = true
                }) {
                    methodCard(title: "メールパスワードログイン", subtitle: "メールアドレスで登録")
                }
                .accessibilityIdentifier("regMethod_email")

                Button(action: {
                    selectedProvider = .phone
                    agreed = false
                    showTerms = true
                }) {
                    methodCard(title: "携帯番号ログイン", subtitle: "SMS で認証")
                }
                .accessibilityIdentifier("regMethod_phone")

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .fullScreenCover(isPresented: $showTerms) {
            TermsOfServiceView(isAgreed: $agreed) {
                showTerms = false
                DispatchQueue.main.async {
                    if selectedProvider == .email {
                        showEmailRegistration = true
                    } else if selectedProvider == .phone {
                        showPhoneRegistration = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showEmailRegistration) {
            EmailRegistrationView()
        }
        .navigationDestination(isPresented: $showPhoneRegistration) {
            PhoneRegistrationView()
        }
    }

    private func methodCard(title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.white.opacity(0.8))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

