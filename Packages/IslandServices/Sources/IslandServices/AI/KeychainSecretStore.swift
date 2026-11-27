import Foundation
import Security

public protocol SecretStoring: Sendable {
    func read(account: String) -> String?
    func save(_ secret: String, account: String) -> Bool
    func delete(account: String)
}

/// Stores user-provided API keys exclusively in the macOS login Keychain (`kSecUseDataProtectionKeychain: false`)
/// so both ad-hoc and Developer ID signed builds work without keychain-access-groups entitlement issues.
public struct KeychainSecretStore: SecretStoring {
    private let service: String

    public init(service: String = "com.kutluhangul.lunula.ai-keys") {
        self.service = service
    }

    public func read(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: false,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ secret: String, account: String) -> Bool {
        let trimmed = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            delete(account: account)
            return false
        }
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: false,
        ]
        let updateAttributes: [CFString: Any] = [
            kSecValueData: data
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }
        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData] = data
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        }
        return false
    }

    public func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: false,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
