// Petit wrapper Keychain : contrairement à UserDefaults, les données Keychain
// survivent à la suppression de l'app (tant que l'appareil n'est pas réinitialisé).
// Utilisé uniquement pour l'accès créateur, afin qu'il ne se perde pas si tu
// réinstalles l'app.

import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.louis.Amena.founderAccess"

    static func setBool(_ value: Bool, forKey key: String) {
        let data = Data([value ? 1 : 0])
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func bool(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data, let byte = data.first else {
            return false
        }
        return byte == 1
    }
}
