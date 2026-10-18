import Foundation

/// Live server state. `online`, `maxPlayers` and `version` are nil while the server is unreachable:
/// the count is unknown, not zero.
public struct NetworkStatus: Codable, Hashable, Sendable {
	public let online: Int?
	public let maxPlayers: Int?
	public let version: String?
	public let address: String
	public let port: Int
	public let season: Int
	public let updatedAt: Date

	public var isReachable: Bool {
		online != nil
	}
}
