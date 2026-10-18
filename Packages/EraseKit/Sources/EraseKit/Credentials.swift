import Foundation
import Security
import Synchronization

/// The session token, kept in memory for requests and in the Keychain across launches.
public final class Credentials: Sendable {

	private let service: String?

	private let current: Mutex<String?>

	/// In-memory only, for tests and previews.
	public init() {
		self.service = nil
		self.current = Mutex(nil)
	}

	/// Backed by a Keychain item that survives app restarts but never leaves this device.
	public init(keychain service: String) {
		self.service = service
		self.current = Mutex(Self.read(service))
	}

	public var token: String? {
		current.withLock { $0 }
	}

	public func store(_ token: String?) {
		current.withLock { $0 = token }
		guard let service else { return }

		let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
		SecItemDelete(query as CFDictionary)

		if let token {
			var item = query
			item[kSecValueData as String] = Data(token.utf8)
			item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
			SecItemAdd(item as CFDictionary, nil)
		}
	}

	private static func read(_ service: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]
		var result: AnyObject?
		guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else {
			return nil
		}
		return String(data: data, encoding: .utf8)
	}
}
