import Foundation

public enum TierBand: String, Codable, Hashable, Sendable {
	case high = "HT"
	case low = "LT"
}

public enum TierMovement: String, Codable, Hashable, Sendable {
	case up
	case down
	case none
}

public enum TierPlatform: String, Codable, Hashable, Sendable, CaseIterable {
	case pc
	case pe
}

public enum TierTestStatus: String, Codable, Hashable, Sendable {
	/// Waiting for an admin to review a high-tier result.
	case pending
	case applied
	case rejected
}

/// A tier test. Placements carry the one behind them, nil when an admin set the tier by hand.
public struct TierTest: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let name: String
	public let tester: String
	public let board: ModeKey
	public let platform: TierPlatform
	public let level: Int
	public let band: TierBand
	public let previousLevel: Int?
	public let previousBand: TierBand?
	/// One grade per board criterion, in the board's `criteria` order.
	public let grades: [Int]
	public let playerScore: Int
	public let testerScore: Int
	public let matchId: Int?
	public let status: TierTestStatus
	public let reviewer: String?
	public let createdAt: Date
	public let reviewedAt: Date?
}

public struct TierPlacement: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let name: String
	public let rank: PlayerRank
	public let board: ModeKey
	public let platform: TierPlatform
	/// 1 (best) to 5.
	public let level: Int
	public let band: TierBand
	public let points: Int
	public let movement: TierMovement
	public let inactive: Bool
	public let updatedAt: Date
	public let test: TierTest?

	/// `HT1`, `LT3`, …
	public var label: String { "\(band.rawValue)\(level)" }
}

public struct TierColumn: Codable, Hashable, Sendable {
	public let level: Int
	public let players: [TierPlacement]
}

public struct TierBoard: Codable, Hashable, Sendable {
	public let board: ModeKey
	public let displayName: String
	public let platform: TierPlatform
	public let season: Int
	public let criteria: [String]
	public let columns: [TierColumn]
}

public struct TierBadge: Codable, Hashable, Sendable {
	public let board: ModeKey
	public let level: Int
	public let band: TierBand
	public let points: Int
	public let inactive: Bool

	public var label: String { "\(band.rawValue)\(level)" }
}

public struct TierStanding: Codable, Hashable, Sendable {
	public let position: Int
	public let name: String
	public let rank: PlayerRank
	public let points: Int
	public let tiers: [TierBadge]
}

public struct TierOverall: Codable, Hashable, Sendable {
	public let platform: TierPlatform
	public let season: Int
	public let players: [TierStanding]
}

/// A player's placements on every board and league, plus their recent tests.
public struct PlayerTiers: Codable, Hashable, Sendable {
	public let name: String
	public let placements: [TierPlacement]
	public let tests: [TierTest]
}
