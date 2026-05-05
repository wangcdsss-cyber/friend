import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PhoneRegistrationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationId: String?

    @State private var year = 1990
    @State private var month = 1
    @State private var day = 1
    @State private var gender: Gender = .male

    @State private var isSending = false
    @State private var isLoading = false
    @State private var countdown = 0
    @State private var errorMessage = ""
    @State private var showToast = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var e164: String? { AuthValidators.normalizedJapaneseE164(from: phoneNumber) }
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
        guard e164 != nil else { return false }
        guard let birthdayDate, BirthdayValidator.isAllowedAge(birthday: birthdayDate) else { return false }
        guard verificationId != nil, verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6 else { return false }
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
                            .accessibilityIdentifier("regPhone_nickname")
                        helperText(NicknameValidator.isValid(nickname) ? " " : "2〜20文字、記号は使用できません")
                    }

                    formField(title: "電話番号", required: true) {
                        TextField("", text: $phoneNumber, prompt: Text("090-1234-5678").foregroundColor(.gray.opacity(0.6)))
                            .keyboardType(.phonePad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .onChange(of: phoneNumber) { _, newValue in
                                let formatted = JapanesePhoneFormatter.formatMobile(newValue)
                                if formatted != newValue { phoneNumber = formatted }
                            }
                            .accessibilityIdentifier("regPhone_phone")
                        helperText(e164 == nil ? "070/080/090 から始まる携帯番号を入力してください" : " ")
                    }

                    formField(title: "認証コード", required: true) {
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
                            .accessibilityIdentifier("regPhone_code")

                        Button(action: sendCode) {
                            if isSending {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(20)
                            } else {
                                Text(countdown > 0 ? "再送信（\(countdown)）" : "認証コードを送信")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(20)
                            }
                        }
                        .disabled(isSending || countdown > 0 || e164 == nil)
                        .accessibilityIdentifier("regPhone_sendCode")
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
                    .accessibilityIdentifier("regPhone_submit")

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
        .onReceive(ticker) { _ in
            if countdown > 0 { countdown -= 1 }
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

    private func sendCode() {
        guard countdown == 0 else { return }
        guard let e164 else {
            errorMessage = "電話番号の形式が正しくありません"
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

    private func register() {
        guard isFormValid else { return }
        guard let birthdayDate else { return }
        guard let verificationId else { return }
        guard let e164 else { return }

        isLoading = true
        errorMessage = ""

        let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)
        Auth.auth().signIn(with: credential) { result, error in
            if let error {
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

            let nick = sanitizedNickname
            let data: [String: Any] = [
                "uid": uid,
                "name": nick,
                "nickname": nick,
                "phoneNumber": e164,
                "birthday": Timestamp(date: birthdayDate),
                "gender": gender.rawValue,
                "profileImageUrl": "",
                "bio": "",
                "provider": "phone",
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
}

