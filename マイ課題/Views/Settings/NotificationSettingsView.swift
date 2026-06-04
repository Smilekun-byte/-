import SwiftUI
import SwiftData
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage(SettingsKeys.notifEnabled) private var notifEnabled = false
    @AppStorage(SettingsKeys.notif1DayBefore) private var notif1Day = true
    @AppStorage(SettingsKeys.notif3HourBefore) private var notif3Hour = false
    @AppStorage(SettingsKeys.notif1HourBefore) private var notif1Hour = false
    @AppStorage(SettingsKeys.notifSyncComplete) private var notifSyncComplete = false

    @Environment(\.modelContext) private var modelContext
    @State private var deniedAlert = false

    var body: some View {
        Form {
            Section {
                Toggle("通知を有効にする", isOn: $notifEnabled)
            } footer: {
                Text("締め切りが近づいた課題をお知らせします。")
                    .font(.caption)
            }

            if notifEnabled {
                Section("リマインダーのタイミング") {
                    Toggle(NotificationTiming.oneDay.label, isOn: $notif1Day)
                    Toggle(NotificationTiming.threeHour.label, isOn: $notif3Hour)
                    Toggle(NotificationTiming.oneHour.label, isOn: $notif1Hour)
                }

                Section {
                    Toggle("同期完了を通知する", isOn: $notifSyncComplete)
                } footer: {
                    Text("Moodle 同期が終わったときに通知します。")
                        .font(.caption)
                }

                Section {
                    Button {
                        NotificationManager.sendTestNotification()
                    } label: {
                        Label("テスト通知を送信", systemImage: "bell.badge")
                    }
                }
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: notifEnabled) { _, newValue in
            if newValue {
                Task { await enableNotifications() }
            } else {
                rescheduleAll()
            }
        }
        .onChange(of: notif1Day) { _, _ in rescheduleAll() }
        .onChange(of: notif3Hour) { _, _ in rescheduleAll() }
        .onChange(of: notif1Hour) { _, _ in rescheduleAll() }
        .alert("通知が許可されていません", isPresented: $deniedAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("iOS の「設定」アプリからマイ課題の通知を許可してください。")
        }
    }

    private func enableNotifications() async {
        let granted = await NotificationManager.requestAuthorization()
        if granted {
            rescheduleAll()
        } else {
            notifEnabled = false
            deniedAlert = true
        }
    }

    private func rescheduleAll() {
        let descriptor = FetchDescriptor<Assignment>()
        guard let all = try? modelContext.fetch(descriptor) else { return }
        NotificationManager.rescheduleAll(assignments: all)
    }
}
