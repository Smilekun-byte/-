import SwiftUI

// MARK: - テーマ

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "システムに合わせる"
        case .light:  return "ライト"
        case .dark:   return "ダーク"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - UserDefaults キー（@AppStorage で参照）

enum SettingsKeys {
    static let universityName  = "settings.universityName"
    static let moodleSiteURL   = "settings.moodleSiteURL"
    static let appTheme        = "settings.appTheme"

    static let notifEnabled       = "settings.notif.enabled"
    static let notif1DayBefore    = "settings.notif.1day"
    static let notif3HourBefore   = "settings.notif.3hour"
    static let notif1HourBefore   = "settings.notif.1hour"
    static let notifSyncComplete  = "settings.notif.syncComplete"
}
