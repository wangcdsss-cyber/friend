import SwiftUI

struct LoginMethodSelectionView: View {
    @State private var showEmailLogin = false
    @State private var showPhoneLogin = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("ログイン方法")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Button(action: { showEmailLogin = true }) {
                    HStack {
                        Text("メール / パスワード")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }
                .accessibilityIdentifier("loginMethod_email")

                Button(action: { showPhoneLogin = true }) {
                    HStack {
                        Text("携帯番号（SMS）")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }
                .accessibilityIdentifier("loginMethod_phone")

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .navigationDestination(isPresented: $showEmailLogin) {
            EmailPasswordLoginView()
        }
        .navigationDestination(isPresented: $showPhoneLogin) {
            PhoneLoginView()
        }
    }
}
