import AppIntents
import SwiftUI
import WidgetKit

struct MaiKadaiWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.smilekun.maikadai.control",
            provider: Provider()
        ) { _ in
            ControlWidgetButton(action: OpenMaiKadaiIntent()) {
                Label("マイ課題", systemImage: "graduationcap.fill")
            }
        }
        .displayName("マイ課題")
        .description("タップしてアプリを開き、課題を確認します。")
    }
}

extension MaiKadaiWidgetControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }
        func currentValue() async throws -> Bool { false }
    }
}

struct OpenMaiKadaiIntent: AppIntent {
    static let title: LocalizedStringResource = "マイ課題を開く"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
