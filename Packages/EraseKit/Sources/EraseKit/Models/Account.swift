import Foundation

/// Who the session belongs to. `configured` is false when the server has no Microsoft sign-in set up.
public struct AuthIdentity: Codable, Hashable, Sendable {
	public let configured: Bool
	public let authenticated: Bool
	/// The linked game player, nil until the account is linked with `/link`.
	public let playerName: String?
	/// `tester`, `moderator`, `admin` or `owner` for staff.
	public let staff: String?
}

public struct AppSession: Codable, Hashable, Sendable {
	public let token: String
	public let expiresAt: Date
}

public struct AuthLinkCode: Codable, Hashable, Sendable {
	public let code: String
	public let expiresAt: Date
}

/// The private account view. Every figure belongs to the signed-in player.
public struct AccountInsights: Codable, Hashable, Sendable {

	public struct Lifetime: Codable, Hashable, Sendable {
		public let playTime: Int
		public let kills: Int
		public let deaths: Int
		public let wins: Int
		public let losses: Int
		public let killStreak: Int
		public let winStreak: Int
		public let dailyStreak: Int
	}

	public struct Averages: Codable, Hashable, Sendable {
		public let matches: Int
		public let hits: Double
		public let criticals: Double
		public let damage: Double
		public let potionAccuracy: Double?
		public let duration: Double
		public let bestCombo: Int
		public let kills: Int
	}

	public struct ActivityDay: Codable, Hashable, Sendable {
		/// `yyyy-MM-dd`.
		public let day: String
		public let games: Int
		public let wins: Int
	}

	public struct ModeShare: Codable, Hashable, Sendable {
		public let mode: ModeKey
		public let games: Int
		public let wins: Int
	}

	public struct Opponent: Codable, Hashable, Sendable {
		public let name: String
		public let games: Int
		public let wins: Int
	}

	public struct UnlockedAchievement: Codable, Hashable, Sendable {
		public let id: String
		public let unlockedAt: Date
	}

	public let name: String
	public let coins: Int
	public let lifetime: Lifetime
	public let averages: Averages
	public let activity: [ActivityDay]
	public let modes: [ModeShare]
	public let opponents: [Opponent]
	public let achievements: [UnlockedAchievement]
	public let metrics: [String: Int]
}
