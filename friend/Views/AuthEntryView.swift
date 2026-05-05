import SwiftUI

struct AuthEntryView: View {
    @State private var showLoginMethods = false
    @State private var showSignUpMethods = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer()

                    Text("Friend")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    Text("同性特化型 掲示板マッチング")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Spacer()

                    Button(action: { showLoginMethods = true }) {
                        Text("アカウントログイン")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(24)
                    }
                    .accessibilityIdentifier("authEntry_login")

                    Button(action: { showSignUpMethods = true }) {
                        Text("新規会員登録")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(24)
                    }
                    .accessibilityIdentifier("authEntry_signup")

                    Spacer().frame(height: 14)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showLoginMethods) {
                LoginMethodSelectionView()
            }
            .navigationDestination(isPresented: $showSignUpMethods) {
                RegistrationMethodSelectionView()
            }
        }
    }
}
