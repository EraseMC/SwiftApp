import Foundation

/// A game mode id as the server writes it (`no_debuff`, `the_bridge`, …).
/// Matches can carry modes the app has never heard of (events such as `towers`), so this is open.
public struct ModeKey: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {

	public let rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}

	public init(stringLiteral value: String) {
		self.rawValue = value
	}

	public init(from decoder: any Decoder) throws {
		rawValue = try decoder.singleValueContainer().decode(String.self)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}

	public static let noDebuff: ModeKey = "no_debuff"
	public static let boxing: ModeKey = "boxing"
	public static let frizmine: ModeKey = "frizmine"
	public static let fireballFight: ModeKey = "fireball_fight"
	public static let mlgRush: ModeKey = "mlg_rush"
	public static let hct: ModeKey = "hct"
	public static let noDebuffFly: ModeKey = "no_debuff_fly"
	public static let sumo: ModeKey = "sumo"
	public static let resistance: ModeKey = "resistance"
	public static let build: ModeKey = "build"
	public static let mace: ModeKey = "mace"
	public static let theBridge: ModeKey = "the_bridge"
	public static let bedFight: ModeKey = "bed_fight"
	public static let battleRush: ModeKey = "battle_rush"
	public static let skywarsOres: ModeKey = "skywars_ores"
	public static let actionPack: ModeKey = "action_pack"
}

/// Presentation metadata for a mode, mirroring the site's catalogue in `lib/data.ts`.
public struct Mode: Hashable, Sendable, Identifiable {

	public enum Bracket: String, Sendable {
		case solo = "1v1"
		case party
	}

	public let key: ModeKey
	public let name: String
	public let bracket: Bracket

	public var id: ModeKey { key }

	/// Asset catalogue name of the mode icon (`Modes/<key>`), in the app bundle.
	public var icon: String { "Modes/\(key.rawValue)" }

	/// Every mode the server has records for, so old matches keep their name and icon.
	public static let catalogue: [ModeKey: Mode] = Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })

	private static let all: [Mode] = [
		Mode(key: .noDebuff, name: "NoDebuff", bracket: .solo),
		Mode(key: .boxing, name: "Boxing", bracket: .solo),
		Mode(key: .frizmine, name: "Frizmine", bracket: .solo),
		Mode(key: .fireballFight, name: "Fireball Fight", bracket: .solo),
		Mode(key: .mlgRush, name: "MLG Rush", bracket: .solo),
		Mode(key: .hct, name: "HCT Teams", bracket: .party),
		Mode(key: .noDebuffFly, name: "NoDebuff Fly", bracket: .solo),
		Mode(key: .sumo, name: "Sumo", bracket: .solo),
		Mode(key: .resistance, name: "Resistance", bracket: .solo),
		Mode(key: .build, name: "Build", bracket: .solo),
		Mode(key: .mace, name: "Mace", bracket: .solo),
		Mode(key: .theBridge, name: "The Bridge", bracket: .solo),
		Mode(key: .bedFight, name: "Bed Fight", bracket: .solo),
		Mode(key: .battleRush, name: "Battle Rush", bracket: .solo),
		Mode(key: .skywarsOres, name: "SkyWars Ores", bracket: .solo),
		Mode(key: .actionPack, name: "Action Pack", bracket: .solo),
	]

	/// Duel modes with a leaderboard, in the order the site lists them.
	public static let ladders: [Mode] = [
		.noDebuff, .boxing, .frizmine, .fireballFight, .mlgRush, .hct, .noDebuffFly,
		.sumo, .mace, .theBridge, .bedFight, .battleRush, .skywarsOres,
	].compactMap { catalogue[$0] }

	/// Disciplines the tier council places players in.
	public static let tiers: [Mode] = [.noDebuff, .boxing, .sumo].compactMap { catalogue[$0] }

	/// The catalogue entry, or a readable fallback for modes the app does not know.
	public static func of(_ key: ModeKey) -> Mode {
		catalogue[key] ?? Mode(
			key: key,
			name: key.rawValue.split(separator: "_").map(\.capitalized).joined(separator: " "),
			bracket: .solo
		)
	}
}

/// Ranked boards order players by Elo, casual boards by unranked wins.
public enum Queue: String, Codable, Hashable, Sendable, CaseIterable {
	case ranked
	case casual
}
