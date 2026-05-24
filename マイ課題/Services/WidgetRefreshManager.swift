import WidgetKit

/// ウィジェットのタイムライン再読み込みをデバウンスして呼び出す。
/// 完了スワイプを連打しても更新要求が間引かれ、バッテリー消費を抑える。
@MainActor
enum WidgetRefreshManager {
    private static var debounceTask: Task<Void, Never>?

    static func scheduleRefresh() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
