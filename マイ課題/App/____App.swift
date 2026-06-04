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
            return try ModelContainer(
                for: Assignment.self, Course.self,
                configurations: config
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var selectedTab = 0
    @AppStorage(SettingsKeys.appTheme) private var themeRaw = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                AssignmentListView()
                    .tabItem { Label("課題", systemImage: "list.bullet") }
                    .tag(0)

                CustomCalendarView()
                    .tabItem { Label("カレンダー", systemImage: "calendar") }
                    .tag(1)

                MatrixView()
                    .tabItem { Label("課題マップ", systemImage: "chart.scatter") }
                    .tag(2)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape") }
                    .tag(3)
            }
            // maikadai://<host> でタップ時に対応タブへジャンプ
            // ※ Xcode の Info.plist に URL スキーム "maikadai" の登録が必要
            .onOpenURL { url in
                switch url.host {
                case "list":   selectedTab = 0
                case "matrix": selectedTab = 2
                default:       break
                }
            }
            .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
