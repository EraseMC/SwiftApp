import Foundation

/// One occupied inventory slot at the end of a match. Slots 0 to 8 are the hotbar.
public struct InventoryItem: Codable, Hashable, Sendable {
	public let slot: Int
	public let item: String
	public let count: Int
	public let enchanted: Bool
}

public struct MatchSide: Codable, Hashable, Sendable {
	public let name: String
	public let team: Int
	public let won: Bool
	public let kills: Int
	public let hits: Int
	public let criticals: Int
	public let damage: Double
	/// Healing potions left over.
	public let pots: Int
	public let accuracy: Double
	public let stolen: Int
	public let eloChange: Int
	public let eloAfter: Int?
	public let combo: Int
	/// Health left in half hearts, nil for matches recorded before it was captured.
	public let health: Double?
	public let inventory: [InventoryItem]?
}

public struct MatchDetail: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let mode: ModeKey
	public let format: String
	public let ranked: Bool
	public let potions: Bool
	/// Seconds.
	public let duration: Int
	public let endedAt: Date
	public let players: [MatchSide]
}

/// A match from one player's point of view.
public struct MatchEntry: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let mode: ModeKey
	public let format: String
	public let ranked: Bool
	public let potions: Bool
	public let duration: Int
	public let endedAt: Date
	public let won: Bool
	public let eloChange: Int
	public let eloAfter: Int?
	public let own: MatchSide
	public let opponents: [MatchSide]
	public let allies: [MatchSide]
}
