import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailRegistrationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var email = ""
    @State private var year = 1990
    @State private var month = 1
    @State private var day = 1
    @State private var gender: Gender = .male
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var mxStatus: MXStatus = .idle
    @State private var mxTask: Task<Void, Never>?

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showToast = false

    private enum MXStatus: Equatable {
        case idle
        case checking
        case ok
        case failed(String)
    }

    private var sanitizedNickname: String { NicknameValidator.sanitized(nickname) }

    private var birthdayDate: Date? {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        c.hour = 0
        c.minute = 0
        c.second = 0
        return Calendar.current.date(from: c)
    }

    private var isFormValid: Bool {
        guard NicknameValidator.isValid(nickname) else { return false }
        guard AuthValidators.isValidEmail(email) else { return false }
        guard let birthdayDate, BirthdayValidator.isAllowedAge(birthday: birthdayDate) else { return false }
        guard AuthValidators.isValidPassword(password) else { return false }
        guard password == confirmPassword else { return false }
        guard mxStatus == .ok else { return false }
        return true
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("無料会員登録")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    formField(title: "ニックネーム", required: true) {
                        TextField("", text: $nickname, prompt: Text("ニックネーム").foregroundColor(.gray.opacity(0.6)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .onChange(of: nickname) { _, newValue in
                                let s = NicknameValidator.sanitized(newValue)
                                if s != newValue { nickname = s }
                            }
                            .accessibilityIdentifier("regEmail_nickname")
                        helperText(NicknameValidator.isValid(nickname) ? " " : "2〜20文字、記号は使用できません")
                    }

                    formField(title: "メールアドレス", required: true) {
                        TextField("", text: $email, prompt: Text("メールアドレス").foregroundColor(.gray.opacity(0.6)))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .onChange(of: email) { _, _ in
                                scheduleMXCheck()
                            }
                            .accessibilityIdentifier("regEmail_email")
                        mxHintView
                    }

                    formField(title: "生年月日", required: true) {
                        HStack(spacing: 10) {
                            Picker("年", selection: $year) {
                                ForEach((1945...2010).reversed(), id: \.self) { y in
                                    Text("\(y)").tag(y)
                                }
                            }
                            Picker("月", selection: $month) {
                                ForEach(1...12, id: \.self) { m in
                                    Text("\(m)").tag(m)
                                }
                            }
                            Picker("日", selection: $day) {
                                ForEach(1...daysInSelectedMonth, id: \.self) { d in
                                    Text("\(d)").tag(d)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .onChange(of: month) { _, _ in normalizeDay() }
                        .onChange(of: year) { _, _ in normalizeDay() }
                        helperText(isBirthdayValid ? " " : "18〜80歳のみ登録できます")
                    }

                    formField(title: "性別", required: true) {
                        HStack(spacing: 12) {
                            genderButton("男性", .male)
                            genderButton("女性", .female)
                        }
                    }

                    formField(title: "パスワード", required: true) {
                        SecureField("", text: $password, prompt: Text("8〜32文字").foregroundColor(.gray.opacity(0.6)))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .accessibilityIdentifier("regEmail_password")
                        helperText(AuthValidators.isValidPassword(password) ? " " : "8〜32文字で入力してください")
                    }

                    formField(title: "パスワード（再入力）", required: true) {
                        SecureField("", text: $confirmPassword, prompt: Text("再入力").foregroundColor(.gray.opacity(0.6)))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .accessibilityIdentifier("regEmail_password2")
                        helperText(confirmPassword.isEmpty || password == confirmPassword ? " " : "パスワードが一致しません")
                            .foregroundColor(confirmPassword.isEmpty || password == confirmPassword ? Color.clear : .red)
                    }

                    Button(action: register) {
                        if isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(24)
                        } else {
                            Text("登録")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(isFormValid ? 0.95 : 0.35))
                                .cornerRadius(24)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .accessibilityIdentifier("regEmail_submit")

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            if showToast {
                VStack {
                    Spacer()
                    Text("ようこそ！")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(18)
                        .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            scheduleMXCheck()
        }
    }

    private var isBirthdayValid: Bool {
        guard let birthdayDate else { return false }
        return BirthdayValidator.isAllowedAge(birthday: birthdayDate)
    }

    private var daysInSelectedMonth: Int {
        var c = DateComponents()
        c.year = year
        c.month = month
        let cal = Calendar.current
        let date = cal.date(from: c) ?? Date()
        return cal.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private func normalizeDay() {
        let max = daysInSelectedMonth
        if day > max { day = max }
    }

    private func genderButton(_ title: String, _ value: Gender) -> some View {
        Button(action: { gender = value }) {
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(gender == value ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                .cornerRadius(24)
        }
    }

    private func formField<Content: View>(title: String, required: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                if required {
                    Text("必須")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(6)
                }
            }
            content()
        }
    }

    private func helperText(_ text: String) -> Text {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.gray)
    }

    @ViewBuilder
    private var mxHintView: some View {
        switch mxStatus {
        case .idle:
            helperText(" ")
        case .checking:
            helperText("ドメインを確認中…")
        case .ok:
            helperText("ドメイン確認OK")
                .foregroundColor(.green)
        case .failed(let msg):
            helperText(msg)
                .foregroundColor(.red)
        }
    }

    private func scheduleMXCheck() {
        mxTask?.cancel()
        errorMessage = ""

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard AuthValidators.isValidEmail(trimmedEmail),
              let domain = trimmedEmail.split(separator: "@").last.map(String.init),
              !domain.isEmpty
        else {
            mxStatus = .idle
            return
        }

        mxStatus = .checking
        mxTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }
            let result = await MXLookupService.checkMX(domain: domain)
            if Task.isCancelled { return }
            await MainActor.run {
                if result.hasMX {
                    mxStatus = .ok
                } else {
                    mxStatus = .failed(result.errorMessage ?? "MXレコードが見つかりません")
                }
            }
        }
    }

    private func register() {
        guard isFormValid else { return }
        guard let birthdayDate else { return }

        isLoading = true
        errorMessage = ""

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let nick = sanitizedNickname

        Auth.auth().createUser(withEmail: trimmedEmail, password: password) { result, error in
            if let error {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = mapAuthError(error)
                }
                return
            }
            guard let uid = result?.user.uid else {
                DispatchQueue.main.async { isLoading = false }
                return
            }

            let data: [String: Any] = [
                "uid": uid,
                "name": nick,
                "nickname": nick,
                "email": trimmedEmail,
                "birthday": Timestamp(date: birthdayDate),
                "gender": gender.rawValue,
                "profileImageUrl": "",
                "bio": "",
                "provider": "email",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            Firestore.firestore().collection("users").document(uid).setData(data) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error {
                        errorMessage = error.localizedDescription
                        return
                    }
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showToast = false
                    }
                    authManager.fetchUser(uid: uid)
                    dismiss()
                }
            }
        }
    }

    private func mapAuthError(_ error: Error) -> String {
        let ns = error as NSError
        if ns.domain == AuthErrorDomain {
            switch ns.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "このメールアドレスは既に登録されています"
            case AuthErrorCode.invalidEmail.rawValue:
                return "メールアドレスの形式が正しくありません"
            case AuthErrorCode.networkError.rawValue:
                return "ネットワークエラーが発生しました"
            default:
                break
            }
        }
        return error.localizedDescription
    }
}

