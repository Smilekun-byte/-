import Foundation
import UserNotifications

// MARK: - 通知タイミング

enum NotificationTiming: String, CaseIterable, Identifiable {
    case oneDay
    case threeHour
    case oneHour

    var id: String { rawValue }

    /// 締め切りから何秒前に通知するか（負の offset）
    var offset: TimeInterval {
        switch self {
        case .oneDay:    return -86400      // 24時間前
        case .threeHour: return -10800      // 3時間前
        case .oneHour:   return -3600       // 1時間前
        }
    }

    var label: String {
        switch self {
        case .oneDay:    return "1日前"
        case .threeHour: return "3時間前"
        case .oneHour:   return "1時間前"
        }
    }

    /// 通知 identifier 用の接尾辞（uid と組み合わせる）
    var suffix: String {
        switch self {
        case .oneDay:    return "1day"
        case .threeHour: return "3hour"
        case .oneHour:   return "1hour"
        }
    }

    var settingsKey: String {
        switch self {
        case .oneDay:    return SettingsKeys.notif1DayBefore
        case .threeHour: return SettingsKeys.notif3HourBefore
        case .oneHour:   return SettingsKeys.notif1HourBefore
        }
    }
}

// MARK: - 通知マネージャ

@MainActor
enum NotificationManager {

    private static let center = UNUserNotificationCenter.current()
    private static let syncCompleteID = "sync_complete"

    // MARK: 権限

    /// 初回タップ時に権限をリクエストする。許可済みなら true を返す。
    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: スケジュール

    /// 設定で有効なタイミングごとに、未来かつ未完了の課題へリマインダーを登録する。
    static func scheduleNotifications(for assignment: Assignment) {
        cancelNotifications(for: assignment)

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: SettingsKeys.notifEnabled) else { return }
        guard !assignment.isCompleted else { return }

        let now = Date()
        for timing in NotificationTiming.allCases {
            guard defaults.bool(forKey: timing.settingsKey) else { continue }

            let fireDate = assignment.deadline.addingTimeInterval(timing.offset)
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = assignment.cleanTitle
            content.body = body(for: assignment, timing: timing)
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(uid: assignment.uid, timing: timing),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    static func cancelNotifications(for assignment: Assignment) {
        let ids = NotificationTiming.allCases.map {
            identifier(uid: assignment.uid, timing: $0)
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// 全課題の通知を組み直す（設定変更・一括同期後に呼ぶ）。
    static func rescheduleAll(assignments: [Assignment]) {
        center.removeAllPendingNotificationRequests()
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: SettingsKeys.notifEnabled) else { return }
        for assignment in assignments {
            scheduleNotifications(for: assignment)
        }
    }

    // MARK: 同期完了通知（デフォルト OFF）

    static func notifySyncComplete(addedCount: Int) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: SettingsKeys.notifEnabled),
              defaults.bool(forKey: SettingsKeys.notifSyncComplete) else { return }

        let content = UNMutableNotificationContent()
        content.title = "同期が完了しました"
        content.body = addedCount > 0
            ? "新しい課題が \(addedCount) 件追加されました。"
            : "課題は最新の状態です。"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: syncCompleteID, content: content, trigger: trigger
        )
        center.add(request)
    }

    // MARK: テスト送信

    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "マイ課題 テスト通知"
        content.body = "通知は正常に届いています 🎓"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_\(UUID().uuidString)", content: content, trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Private

    private static func identifier(uid: String, timing: NotificationTiming) -> String {
        "\(uid)_\(timing.suffix)"
    }

    private static func body(for assignment: Assignment, timing: NotificationTiming) -> String {
        var text = "締め切りまで\(timing.label)です。"
        if assignment.isMidnightDeadline {
            text += "（締め切りは前日深夜0:00の可能性があります。早めの確認を）"
        }
        return text
    }
}
