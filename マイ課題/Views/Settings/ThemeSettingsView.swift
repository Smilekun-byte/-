import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage(SettingsKeys.appTheme) private var themeRaw = AppTheme.system.rawValue

    var body: some View {
        Form {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        themeRaw = theme.rawValue
                    } label: {
                        HStack {
                            Text(theme.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            if themeRaw == theme.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            } footer: {
                Text("選択したテーマはアプリ全体に即座に反映されます。")
                    .font(.caption)
            }
        }
        .navigationTitle("テーマ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
