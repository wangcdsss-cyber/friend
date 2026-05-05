import SwiftUI
import UIKit

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isAgreed: Bool
    let onProceed: () -> Void

    @State private var localAgreed = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Text("戻る")
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text("利用規約")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("戻る").opacity(0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(white: 0.96))

                VStack(spacing: 12) {
                    GeometryReader { geo in
                        ScrollView {
                            Text(tosText)
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.86))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                        }
                        .frame(height: min(geo.size.height, UIScreen.main.bounds.height * 0.60))
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.60)

                    VStack(spacing: 10) {
                        Toggle(isOn: $localAgreed) {
                            Text("上記利用規約の内容に同意します。")
                                .foregroundColor(localAgreed ? .orange : .gray)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .tint(.orange)
                        .onChange(of: localAgreed) { _, newValue in
                            isAgreed = newValue
                        }

                        Button(action: {
                            onProceed()
                        }) {
                            Text("会員登録へ進む")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(localAgreed ? Color.orange : Color.orange.opacity(0.35))
                                .cornerRadius(10)
                        }
                        .disabled(!localAgreed)
                        .animation(.easeInOut(duration: 0.2), value: localAgreed)
                    }
                    .padding(12)
                    .background(Color(white: 0.96))
                    .cornerRadius(10)
                }
                .padding(14)
                .background(Color(white: 0.96))
            }
            .cornerRadius(14)
            .padding(.horizontal, 14)
        }
        .onAppear {
            localAgreed = isAgreed
        }
    }

    private var tosText: AttributedString {
        var s = AttributedString("""
【個人情報の取り扱い】
当サービスは、会員登録およびサービス提供のために、ニックネーム、生年月日、性別、メールアドレスまたは電話番号等の情報を取得します。取得した個人情報は、本人確認、認証、問い合わせ対応、不正利用防止、サービス改善の目的に限り利用します。法令に基づく場合を除き、本人の同意なく第三者に提供しません。通信は暗号化（HTTPS/TLS）により保護されます。登録情報の変更・削除の手続きについては、本規約の「退会手続き」に従います。

【禁止事項】
会員は、以下の行為を行ってはなりません。法令または公序良俗に反する行為、差別・誹謗中傷・嫌がらせ、脅迫、過度に性的な表現、わいせつ・暴力的または不快感を与えるコンテンツの投稿、スパム、なりすまし、個人情報（住所・勤務先等）の不適切な共有、外部サービスへの誘導、売買・勧誘、運営の許可なく自動化された手段でアクセスする行為、システムに過度な負荷をかける行為、当社または第三者の権利を侵害する行為、その他運営が不適切と判断する行為。違反が確認された場合、事前通知なく投稿の削除、機能制限、アカウント停止等の措置を行うことがあります。

【退会手続き】
会員は、アプリ内の手続きにより退会できます。退会後、認証情報およびユーザー情報は、法令上の保存義務や不正対策等の正当な理由がある場合を除き、合理的な期間内に削除または匿名化します。退会前に作成した投稿・メッセージ等の取り扱いは、サービスの健全性維持やトラブル対応のため、一定期間保持する場合があります。退会により、未消化の特典・権利は消滅し、復旧できない場合があります。

上記に同意のうえ、会員登録へお進みください。
""")

        if let r1 = s.range(of: "【個人情報の取り扱い】") { s[r1].font = .system(size: 15, weight: .bold) }
        if let r2 = s.range(of: "【禁止事項】") { s[r2].font = .system(size: 15, weight: .bold) }
        if let r3 = s.range(of: "【退会手続き】") { s[r3].font = .system(size: 15, weight: .bold) }
        return s
    }
}
