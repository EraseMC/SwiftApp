import Foundation

public struct LadderEntry: Codable, Hashable, Sendable {
	public let place: Int
	public let name: String
	public let rank: PlayerRank
	/// Nil on casual boards, which rank by wins.
	public let elo: Int?
	public let games: Int
	public let wins: Int
	public let losses: Int
}

public struct Leaderboard: Codable, Hashable, Sendable {
	/// `global` or a mode key.
	public let board: String
	public let queue: Queue
	public let displayName: String
	public let season: Int
	public let entries: [LadderEntry]
}
