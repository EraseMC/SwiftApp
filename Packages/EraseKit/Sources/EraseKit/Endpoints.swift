import Foundation

/// Every public Imprint call the site makes, with the site's default sizes.
public enum API {

	public static let networkStatus = Endpoint<NetworkStatus>("network/status")

	public static func leaderboard(_ board: String, queue: Queue = .ranked, limit: Int = 50) -> Endpoint<Leaderboard> {
		Endpoint("leaderboards/\(board)", query: [
			URLQueryItem(name: "queue", value: queue.rawValue),
			URLQueryItem(name: "limit", value: String(limit)),
		])
	}

	public static func searchPlayers(_ query: String, limit: Int = 5) -> Endpoint<[PlayerCard]> {
		Endpoint("players", query: [
			URLQueryItem(name: "q", value: query),
			URLQueryItem(name: "limit", value: String(limit)),
		])
	}

	public static func player(_ name: String) -> Endpoint<PlayerProfile> {
		Endpoint("players/\(name)")
	}

	public static func ladder(_ name: String, mode: ModeKey) -> Endpoint<LadderStats> {
		Endpoint("players/\(name)/ladders/\(mode.rawValue)")
	}

	/// Newest first. Page with `before`, the `endedAt` of the last match already shown.
	public static func matches(
		_ name: String,
		mode: ModeKey? = nil,
		queue: Queue? = nil,
		before: Date? = nil,
		limit: Int = 20
	) -> Endpoint<[MatchEntry]> {
		var query = [URLQueryItem(name: "limit", value: String(limit))]
		if let mode {
			query.append(URLQueryItem(name: "mode", value: mode.rawValue))
		}
		if let queue {
			query.append(URLQueryItem(name: "queue", value: queue.rawValue))
		}
		if let before {
			query.append(URLQueryItem(name: "before", value: String(Int(before.timeIntervalSince1970))))
		}
		return Endpoint("players/\(name)/matches", query: query)
	}

	/// Oldest first, ready to plot.
	public static func eloHistory(_ name: String, mode: ModeKey? = nil, limit: Int = 200) -> Endpoint<[EloPoint]> {
		var query = [URLQueryItem(name: "limit", value: String(limit))]
		if let mode {
			query.append(URLQueryItem(name: "mode", value: mode.rawValue))
		}
		return Endpoint("players/\(name)/elo-history", query: query)
	}

	public static func playerTiers(_ name: String) -> Endpoint<PlayerTiers> {
		Endpoint("players/\(name)/tiers")
	}

	public static func match(_ id: Int) -> Endpoint<MatchDetail> {
		Endpoint("matches/\(id)")
	}

	public static func tierBoard(_ board: ModeKey, platform: TierPlatform) -> Endpoint<TierBoard> {
		Endpoint("tiers", query: [
			URLQueryItem(name: "board", value: board.rawValue),
			URLQueryItem(name: "platform", value: platform.rawValue),
		])
	}

	public static func tierOverall(platform: TierPlatform, limit: Int = 100) -> Endpoint<TierOverall> {
		Endpoint("tiers/overall", query: [
			URLQueryItem(name: "platform", value: platform.rawValue),
			URLQueryItem(name: "limit", value: String(limit)),
		])
	}

	public static func clubs(limit: Int = 20) -> Endpoint<[ClubCard]> {
		Endpoint("clubs", query: [URLQueryItem(name: "limit", value: String(limit))])
	}

	public static func clubSeason(limit: Int = 20) -> Endpoint<ClubSeason> {
		Endpoint("clubs/season", query: [URLQueryItem(name: "limit", value: String(limit))])
	}

	public static func clubWars(limit: Int = 12) -> Endpoint<[ClubWar]> {
		Endpoint("clubs/wars", query: [URLQueryItem(name: "limit", value: String(limit))])
	}

	public static func clubTournaments(limit: Int = 8) -> Endpoint<[ClubTournament]> {
		Endpoint("clubs/tournaments", query: [URLQueryItem(name: "limit", value: String(limit))])
	}

	/// Clubs are addressed by name, as the site links them.
	public static func club(_ name: String) -> Endpoint<ClubProfile> {
		Endpoint("clubs/\(name)")
	}

	public static let me = Endpoint<AuthIdentity>("auth/me")

	public static let linkCode = Endpoint<AuthLinkCode>("auth/link-code", method: .post)

	public static let logout = Endpoint<AuthIdentity>("auth/logout", method: .post)

	/// Trades the one-time ticket from the sign-in redirect and the PKCE verifier for a session.
	public static func appToken(ticket: String, verifier: String) -> Endpoint<AppSession> {
		Endpoint("auth/app/token", method: .post, json: ["ticket": ticket, "verifier": verifier])
	}

	/// Where the app starts the Microsoft sign-in, carrying its PKCE challenge.
	public static func signInURL(challenge: String, base: URL = APIClient.production.baseURL) -> URL {
		var url = base.appending(path: "auth/microsoft")
		url.append(queryItems: [URLQueryItem(name: "app", value: challenge)])
		return url
	}

	public static let accountInsights = Endpoint<AccountInsights>("account/insights")

	/// PNG renders of a player's skin.
	public static func skinURL(_ name: String, part: SkinPart, size: Int, base: URL = APIClient.production.baseURL) -> URL {
		let path = switch part {
		case .head: "players/\(name)/skin/head"
		case .body: "players/\(name)/skin/body"
		case .texture: "players/\(name)/skin"
		}
		var url = base.appending(path: path)
		if part != .texture {
			url.append(queryItems: [URLQueryItem(name: "size", value: String(size))])
		}
		return url
	}

	public enum SkinPart: Sendable {
		case head
		case body
		case texture
	}
}
