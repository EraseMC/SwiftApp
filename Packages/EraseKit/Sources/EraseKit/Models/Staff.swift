import Foundation

/// What a rank may do in the staff panel, decided by the same priority the game uses.
public enum StaffRole: String, Codable, Hashable, Sendable, Comparable {
	case tester
	case moderator
	case admin
	case owner

	private var priority: Int {
		switch self {
		case .tester: 40
		case .moderator: 50
		case .admin: 90
		case .owner: 100
		}
	}

	public static func < (lhs: StaffRole, rhs: StaffRole) -> Bool {
		lhs.priority < rhs.priority
	}
}

public struct StaffMember: Codable, Hashable, Sendable {
	public let id: Int
	public let name: String
	public let rank: PlayerRank
	public let role: StaffRole
	/// `overview`, `tiers`, `players`, `reviews`, `testers`, `team`.
	public let sections: [String]
}

public struct StaffLogRow: Codable, Hashable, Sendable {
	public let staff: String
	public let action: String
	public let target: String
	public let details: String
	public let at: Date
}

public struct StaffOverview: Codable, Hashable, Sendable {
	public let me: StaffMember
	public let online: Int?
	/// Waiting players per `board:platform`.
	public let queue: [String: Int]
	public let pendingReviews: Int?
	public let myTestsWeek: Int?
	public let myTests: Int?
	public let activeBans: Int?
	public let activeMutes: Int?
	public let recent: [StaffLogRow]
}

public struct StaffPlayerRow: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	public let lastSeen: Date
}

public struct PunishmentRow: Codable, Hashable, Sendable, Identifiable {
	public let id: Int
	/// `ban`, `mute` or `kick`.
	public let type: String
	public let reason: String
	public let executor: String
	public let createdAt: Date
	/// Epoch 0 for permanent punishments.
	public let expiresAt: Date
	public let active: Bool
}

public struct AltRow: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	/// How the alt was matched: device, IP, …
	public let via: String
	public let banned: Bool
}

public struct StaffPlayerCard: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	public let online: Bool?
	public let firstSeen: Date
	public let lastSeen: Date
	public let playTime: Int
	public let device: String?
	public let punishments: [PunishmentRow]
	public let alts: [AltRow]
	public let tiers: [TierPlacement]
	public let history: [StaffLogRow]
	public let canPunish: Bool
	public let canRank: Bool
}

public struct StaffActionResult: Codable, Hashable, Sendable {
	/// Whether the command reached the game over RCON.
	public let sent: Bool
	/// What the game answered.
	public let output: String
}

public struct TierQueueEntry: Codable, Hashable, Sendable {
	public let position: Int
	public let name: String
	public let rank: PlayerRank
	public let board: ModeKey
	public let platform: TierPlatform
	public let joinedAt: Date
}

public struct TesterStats: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	public let tests: Int
	public let recent: Int
	public let pending: Int
	public let rejected: Int
	public let lastAt: Date
	/// Tiers given, keyed `HT3`, `LT1`, …
	public let given: [String: Int]
}

public struct TeamMember: Codable, Hashable, Sendable {
	public let name: String
	public let rank: PlayerRank
	public let role: String
	public let online: Bool?
	public let lastSeen: Date
	public let bans: Int
	public let mutes: Int
	public let kicks: Int
	public let tests: Int
	public let testsWeek: Int
}

extension API {

	public enum Staff {

		public static let me = Endpoint<StaffMember>("staff/me")

		public static let overview = Endpoint<StaffOverview>("staff/overview")

		public static let team = Endpoint<[TeamMember]>("staff/team")

		public static let ranks = Endpoint<[PlayerRank]>("staff/ranks")

		public static func players(_ query: String) -> Endpoint<[StaffPlayerRow]> {
			Endpoint("staff/players", query: [URLQueryItem(name: "q", value: query)])
		}

		public static func player(_ name: String) -> Endpoint<StaffPlayerCard> {
			Endpoint("staff/players/\(name)")
		}

		/// `type` is `ban`, `mute` or `kick`; `duration` like `30m`, `7d` or `perm` (ignored for kicks).
		public static func punish(_ name: String, type: String, duration: String, reason: String) -> Endpoint<StaffActionResult> {
			Endpoint("staff/players/\(name)/punish", method: .post, json: ["type": type, "duration": duration, "reason": reason])
		}

		public static func pardon(_ name: String, type: String) -> Endpoint<StaffActionResult> {
			Endpoint("staff/players/\(name)/pardon", method: .post, json: ["type": type])
		}

		public static func setRank(_ name: String, rank: String) -> Endpoint<StaffActionResult> {
			Endpoint("staff/players/\(name)/rank", method: .post, json: ["rank": rank])
		}

		public static let tierQueue = Endpoint<[TierQueueEntry]>("staff/tiers/queue")

		public static func tests(mine: Bool) -> Endpoint<[TierTest]> {
			Endpoint("staff/tiers/tests", query: [URLQueryItem(name: "mine", value: String(mine))])
		}

		public static let testers = Endpoint<[TesterStats]>("staff/tiers/testers")

		public static let reviews = Endpoint<[TierTest]>("staff/tiers/reviews")

		public static func review(_ id: Int, approve: Bool) -> Endpoint<StaffActionResult> {
			Endpoint("staff/tiers/reviews/\(id)", method: .post, query: [URLQueryItem(name: "approve", value: String(approve))])
		}

		/// Owner only. `tier` like `HT3`.
		public static func place(_ name: String, board: ModeKey, platform: TierPlatform, tier: String) -> Endpoint<StaffActionResult> {
			Endpoint("staff/tiers/placements", method: .put, json: [
				"name": name, "board": board.rawValue, "platform": platform.rawValue, "tier": tier,
			])
		}

		/// Owner only.
		public static func removePlacement(_ id: Int) -> Endpoint<StaffActionResult> {
			Endpoint("staff/tiers/placements/\(id)", method: .delete)
		}
	}
}
