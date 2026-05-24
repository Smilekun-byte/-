import Foundation
import Security

/// Moodle iCal URL の安全な保存・取得を担う Keychain ラッパー。
/// URL には authtoken が含まれるため UserDefaults ではなく Keychain に保存する。
enum KeychainManager {

    private static let service = Bundle.main.bundleIdentifier ?? "com.smilekun.moodlehelper"
    private static let account = "moodle_ical_url"

    static func saveURL(_ urlString: String) throws {
        guard let data = urlString.data(using: .utf8) else { return }
        delete()
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData:   data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func loadURL() -> String? {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  account,
            kSecReturnData:   true,
            kSecMatchLimit:   kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete() -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)

        var errorDescription: String? {
            if case .saveFailed(let s) = self {
                return "Keychain の保存に失敗しました（OSStatus: \(s)）"
            }
            return nil
        }
    }
}
