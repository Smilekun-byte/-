import SwiftUI

struct AboutView: View {
    private let githubURL = URL(string: "https://github.com/smilekun/maikadai")!

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("バージョン", value: appVersion)
                LabeledContent("ライセンス", value: "MIT License")
            }

            Section {
                Link(destination: githubURL) {
                    Label("GitHub リポジトリ", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }

            Section("免責事項") {
                Text("本アプリは Moodle の非公式クライアントです。表示される締め切り情報は Moodle の iCal データに基づきますが、その正確性・完全性は保証されません。重要な締め切りは必ず Moodle 公式サイトでご確認ください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("アプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}
