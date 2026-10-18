import Foundation
import Testing
@testable import EraseKit

/// Real responses captured from erasemc.com, so a model that drifts from the API fails here first.
@Suite struct FixtureTests {

	private func load<T: Decodable>(_ name: String, as type: T.Type = T.self) throws -> T {
		let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
		return try JSONDecoder.imprint.decode(T.self, from: Data(contentsOf: url))
	}

	@Test func leaderboards() throws {
		let ranked: Leaderboard = try load("leaderboard-global")
		#expect(ranked.queue == .ranked)
		#expect(ranked.entries.first?.place == 1)

		let casual: Leaderboard = try load("leaderboard-casual")
		#expect(casual.queue == .casual)
	}

	@Test func player() throws {
		let profile: PlayerProfile = try load("player")
		#expect(profile.player.name == "khaoslxng")
		#expect(!profile.ladders.isEmpty)
		#expect(profile.casual.elo == nil)
	}

	@Test func playerParts() throws {
		_ = try load("player-search", as: [PlayerCard].self)
		_ = try load("player-ladder", as: LadderStats.self)
		let matches = try load("player-matches", as: [MatchEntry].self)
		#expect(!matches.isEmpty)
		let history = try load("player-elo", as: [EloPoint].self)
		#expect(history.first?.endedAt.timeIntervalSince1970 == 1_790_800_768)
	}

	@Test func match() throws {
		let match: MatchDetail = try load("match")
		#expect(match.id == 804)
		#expect(match.players.count >= 2)
	}

	@Test func tiers() throws {
		let board: TierBoard = try load("tiers")
		#expect(board.columns.count == 5)
		#expect(board.columns.flatMap(\.players).contains { $0.test != nil })
		_ = try load("tiers-overall", as: TierOverall.self)
	}

	@Test func clubs() throws {
		_ = try load("clubs", as: [ClubCard].self)
		_ = try load("club-season", as: ClubSeason.self)
		_ = try load("club-wars", as: [ClubWar].self)
		_ = try load("club-tournaments", as: [ClubTournament].self)
		let club: ClubProfile = try load("club")
		#expect(club.club.name == "Erase")
	}

	@Test func network() throws {
		_ = try load("network-status", as: NetworkStatus.self)
		let me: AuthIdentity = try load("auth-me")
		#expect(!me.authenticated)
	}

	@Test func unknownModesStayReadable() {
		#expect(Mode.of("towers").name == "Towers")
		#expect(Mode.of(.noDebuff).name == "NoDebuff")
		#expect(Mode.ladders.count == 13)
	}
}
