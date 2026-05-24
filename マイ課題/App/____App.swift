import SwiftUI
import SwiftData

@main
struct マイ課題App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Assignment.self])

        // App Groups が有効なら共有コンテナに、未設定なら通常パスにフォールバック
        let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupID)?
            .appending(path: "マイ課題.store")

        let config: ModelConfiguration
        if let url = storeURL {
            config = ModelConfiguration(schema: schema, url: url)
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
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
