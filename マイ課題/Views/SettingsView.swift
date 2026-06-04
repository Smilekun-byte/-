import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        UniversitySettingsView()
                    } label: {
                        Label("大学情報", systemImage: "building.columns")
                    }

                    NavigationLink {
                        MoodleSyncSettingsView()
                    } label: {
                        Label("Moodle 連携", systemImage: "arrow.triangle.2.circlepath")
                    }

                    NavigationLink {
                        CourseManagementView()
                    } label: {
                        Label("課程管理", systemImage: "books.vertical")
                    }
                }

                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("通知設定", systemImage: "bell")
                    }

                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        Label("テーマ", systemImage: "paintbrush")
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("アプリについて", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}
