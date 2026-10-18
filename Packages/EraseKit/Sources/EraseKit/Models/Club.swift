import Foundation

/// A club as it appears in lists. `place` is its position by Elo among all clubs.
public struct ClubCard: Codable, Hashable, Sendable {
	public let place: Int
	public let name: String
	public let tag: String
	public let elo: Int
	public let wins: Int
	public let losses: Int
	public let members: Int
	public let memberLimit: Int
	public let motto: String
}

public struct ClubMember: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	/// `owner`, `officer` or `member`.
	public let role: String
	public let contributed: Int
	public let joinedAt: Date
	public let lastSeen: Date
}

public struct ClubWarSide: Codable, Hashable, Sendable {
	public let name: String
	public let tag: String
	public let elo: Int
	public let players: [String]
}

public struct ClubWar: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let mode: ModeKey
	public let winner: ClubWarSide
	public let loser: ClubWarSide
	public let eloChange: Int
	public let endedAt: Date
}

public struct ClubTournament: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let mode: ModeKey
	public let clubs: Int
	public let fee: Int
	public let pot: Int
	public let championName: String
	public let championTag: String
	public let championPrize: Int
	public let runnerUpName: String?
	public let runnerUpTag: String?
	public let endedAt: Date
}

public struct ClubSeasonResult: Codable, Hashable, Sendable {
	public let season: Int
	public let place: Int
	public let elo: Int
	public let wins: Int
	public let losses: Int
	public let reward: Int
	public let endedAt: Date
}

public struct ClubAchievement: Codable, Hashable, Sendable {
	public let id: String
	public let holders: Int
}

public struct ClubUpgrade: Codable, Hashable, Sendable {
	public let limit: Int
	public let maxLimit: Int
	public let nextLimit: Int?
	public let nextCost: Int?
}

public struct ClubProfile: Codable, Hashable, Sendable {
	public let club: ClubCard
	public let owner: String
	public let privacy: String
	public let createdAt: Date
	public let coins: Int
	public let members: [ClubMember]
	public let warsWon: Int
	public let warsLost: Int
	public let wars: [ClubWar]
	public let tournamentsWon: Int
	public let tournaments: [ClubTournament]
	public let seasons: [ClubSeasonResult]
	public let achievements: [ClubAchievement]
	public let upgrade: ClubUpgrade
}

public struct ClubSeason: Codable, Hashable, Sendable {
	public let number: Int
	public let startedAt: Date
	public let endsAt: Date
	public let standings: [ClubCard]
}
