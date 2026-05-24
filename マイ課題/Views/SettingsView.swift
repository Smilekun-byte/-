import SwiftUI

struct SettingsView: View {
    @State private var urlInput: String = ""
    @State private var showSuccessBanner = false
    @State private var saveError: String?
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                urlSection
                securitySection
            }
            .navigationTitle("設定")
            .onAppear(perform: loadExistingURL)
            .overlay(alignment: .top) { successBanner }
            .alert("保存エラー", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var urlSection: some View {
        Section {
            TextField("https://moodle.example.ac.jp/calendar/export...", text: $urlInput)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFieldFocused)

            Button(action: saveURL) {
                HStack {
                    Spacer()
                    Text("URLを安全に保存")
                        .bold()
                    Spacer()
                }
            }
            .disabled(urlInput.trimmingCharacters(in: .whitespaces).isEmpty)
        } header: {
            Text("Moodle iCal URL 設定")
        } footer: {
            Text("Moodleの「ダッシュボード」→「カレンダー」→「カレンダーをエクスポート」から取得したプライベート iCal URLを入力してください。このURLには認証トークンが含まれるため、Keychainに暗号化して保存されます。")
                .font(.caption)
        }
    }

    private var securitySection: some View {
        Section("セキュリティ") {
            HStack {
                Label("データ保護", systemImage: "lock.shield.fill")
                    .foregroundStyle(.green)
                Spacer()
                Text("iOS Keychain 暗号化")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if KeychainManager.loadURL() != nil {
                HStack {
                    Label("URL 登録済み", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                    Spacer()
                    Button("削除", role: .destructive) {
                        KeychainManager.delete()
                        urlInput = ""
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var successBanner: some View {
        Group {
            if showSuccessBanner {
                Text("URLを正常に保存しました 🔒")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.green.opacity(0.9))
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.4), value: showSuccessBanner)
    }

    // MARK: - Logic

    private func loadExistingURL() {
        urlInput = KeychainManager.loadURL() ?? ""
    }

    private func saveURL() {
        isFieldFocused = false
        let trimmed = urlInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        do {
            try KeychainManager.saveURL(trimmed)
            withAnimation { showSuccessBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation { showSuccessBanner = false }
            }
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
}
