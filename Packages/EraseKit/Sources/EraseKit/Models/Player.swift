import Foundation

public struct PlayerRank: Codable, Hashable, Sendable {
	public let id: Int
	public let name: String
	public let displayName: String
	/// `#RRGGBB`, the Minecraft colour of the rank.
	public let color: String
	public let priority: Int
}

/// A search hit or a leaderboard row's player.
public struct PlayerCard: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	public let peakElo: Int
}

public struct PlayerIdentity: Codable, Hashable, Sendable {
	public let id: Int
	public let name: String
	public let rank: PlayerRank
	/// `yyyy-MM-dd`.
	public let joined: String
	public let banned: Bool
	public let coins: Int
	public let friends: Int
}

public struct PlayerSummary: Codable, Hashable, Sendable {
	public let kills: Int
	public let deaths: Int
	public let wins: Int
	public let losses: Int
	public let killStreak: Int
	public let winStreak: Int
	public let dailyStreak: Int
	/// Seconds.
	public let playTime: Int
	public let peakElo: Int
	public let rankedWins: Int
	public let casualWins: Int
	public let winRate: Double
}

public struct DivisionProgress: Codable, Hashable, Sendable {
	public let current: String
	public let next: String
	public let winsToNext: Int
	public let percent: Int
}

/// Unranked games of one mode. The division is the title those wins earn.
public struct CasualStats: Codable, Hashable, Sendable {
	public let games: Int
	public let wins: Int
	public let losses: Int
	public let winRate: Double
	public let division: DivisionProgress
}

public struct LadderStats: Codable, Hashable, Sendable {
	public let mode: ModeKey
	public let displayName: String
	public let bracket: String
	public let elo: Int
	public let games: Int
	public let wins: Int
	public let losses: Int
	public let peak: Int
	public let winRate: Double
	public let played: Bool
	public let division: DivisionProgress
	/// Place on this mode's ranked board, nil when unplaced.
	public let place: Int?
	public let casual: CasualStats
}

/// `online` is nil when the game server could not be asked.
public struct PlayerPresence: Codable, Hashable, Sendable {
	public let online: Bool?
	public let lastSeen: Date
}

public struct PlayerClub: Codable, Hashable, Sendable {
	public let name: String
	public let tag: String
	public let role: String
}

public struct PlayerFriend: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
}

/// Standing in one queue. `elo` is the global rating on ranked and nil on casual.
public struct QueueSummary: Codable, Hashable, Sendable {
	public let elo: Int?
	public let place: Int?
	public let peak: Int
	public let games: Int
	public let wins: Int
	public let losses: Int
	public let winRate: Double
}

public struct CasualTitle: Codable, Hashable, Sendable {
	public let mode: ModeKey
	public let displayName: String
	public let division: String
}

public struct PlayerProfile: Codable, Hashable, Sendable {
	public let player: PlayerIdentity
	public let summary: PlayerSummary
	public let ladders: [LadderStats]
	public let presence: PlayerPresence
	public let club: PlayerClub?
	public let friends: [PlayerFriend]
	public let ranked: QueueSummary
	public let casual: QueueSummary
	public let casualTitle: CasualTitle?

	public func summary(for queue: Queue) -> QueueSummary {
		queue == .ranked ? ranked : casual
	}
}

public struct EloPoint: Codable, Hashable, Sendable {
	public let endedAt: Date
	public let mode: ModeKey
	public let elo: Int
	public let change: Int
}
