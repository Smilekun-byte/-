import Foundation
import Combine

/// 課題の締め切り密集度を表す熱量レベル
enum DeadlineHeat {
    case safe    // 課題なし
    case normal  // 1〜2個
    case warning // 3〜4個
    case hell    // 5個以上

    var dotColor: (red: Double, green: Double, blue: Double)? {
        switch self {
        case .safe:    return nil
        case .normal:  return (1.0, 0.8, 0.0)  // yellow
        case .warning: return (1.0, 0.5, 0.0)  // orange
        case .hell:    return (1.0, 0.2, 0.2)  // red
        }
    }
}

class CalendarViewModel: ObservableObject {

    /// 日付文字列キー → 熱量レベルの辞書。View 側は O(1) で参照できる。
    @Published private(set) var heatMap: [String: DeadlineHeat] = [:]

    private var assignments: [Assignment] = []

    /// 課題配列を受け取り、ヒートマップを一括で事前計算する。
    /// View の body 内では呼ばず、onChange で呼び出すこと（描画ブロック防止）。
    @MainActor
    func precomputeHeatMap(from assignments: [Assignment]) {
        self.assignments = assignments

        var countMap: [String: Int] = [:]
        for a in assignments where !a.isCompleted {
            let key = CalendarProvider.shared.makeStringKey(from: a.deadline)
            countMap[key, default: 0] += 1
        }

        heatMap = countMap.mapValues { count in
            switch count {
            case 1...2: return .normal
            case 3...4: return .warning
            default:    return .hell
            }
        }
    }

    /// 指定した日の未完了課題を返す（文字列キー突合による高速フィルタリング）
    func getTasks(for date: Date) -> [Assignment] {
        let key = CalendarProvider.shared.makeStringKey(from: date)
        return assignments.filter {
            !$0.isCompleted &&
            CalendarProvider.shared.makeStringKey(from: $0.deadline) == key
        }
    }
}
