import SwiftUI
import SwiftData

@main
struct マイ課題App: App {
    var sharedModelContainer: ModelContainer = {
        // App Groups が有効なら共有コンテナに、未設定なら通常パスにフォールバック
        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupID)?
            .appending(path: "マイ課題.store")

        let config: ModelConfiguration
        if let url = storeURL {
            config = ModelConfiguration(url: url)
        } else {
            config = ModelConfiguration()
        }

        do {
            // MigrationPlan を使って V1 → V2 ライトウェイトマイグレーションを自動適用
            return try ModelContainer(
                for: Assignment.self, Course.self,
                migrationPlan: MaiKadaiMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                AssignmentListView()
                    .tabItem { Label("課題", systemImage: "list.bullet") }

                CustomCalendarView()
                    .tabItem { Label("カレンダー", systemImage: "calendar") }

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape") }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
