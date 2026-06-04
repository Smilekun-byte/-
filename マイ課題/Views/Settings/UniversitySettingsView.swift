import SwiftUI

struct UniversitySettingsView: View {
    @AppStorage(SettingsKeys.universityName) private var universityName = ""
    @AppStorage(SettingsKeys.moodleSiteURL) private var moodleSiteURL = ""
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section("大学名") {
                TextField("○○大学", text: $universityName)
                    .autocorrectionDisabled()
            }

            Section {
                TextField("https://moodle.example.ac.jp", text: $moodleSiteURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if let url = validURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Safari で Moodle を開く", systemImage: "safari")
                    }
                }
            } header: {
                Text("Moodle 公式サイト")
            } footer: {
                Text("大学の Moodle トップページの URL を登録すると、ここからすぐにアクセスできます。")
                    .font(.caption)
            }
        }
        .navigationTitle("大学情報")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var validURL: URL? {
        let trimmed = moodleSiteURL.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("http"), let url = URL(string: trimmed) else { return nil }
        return url
    }
}
