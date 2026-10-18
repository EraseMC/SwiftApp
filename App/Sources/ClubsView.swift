import EraseKit
import EraseUI
import SwiftUI

/// Club season standings, recent wars and tournaments, shown inside the Leaderboards tab.
struct ClubsSection: View {

	@Environment(AppModel.self) private var model

	@State private var season: Phase<ClubSeason> = .loading

	@State private var wars: [ClubWar] = []

	@State private var tournaments: [ClubTournament] = []

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s4) {
			LoadState(season, retry: load) { season in
				VStack(alignment: .leading, spacing: Space.s3) {
					HStack(alignment: .firstTextBaseline) {
						Text(verbatim: Copy.text("clubs.season", ["number": season.number]))
							.font(.eraseTitle3)
						Spacer()
						Text(season.endsAt, format: .relative(presentation: .named))
							.font(.eraseFootnote)
							.foregroundStyle(Palette.text3)
					}

					VStack(spacing: 0) {
						ForEach(season.standings, id: \.name) { club in
							NavigationLink(value: Route.club(club.name)) {
								ClubRow(club: club)
							}
							.buttonStyle(.pressable)
						}
					}
					.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
					.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))
				}
			}

			if !wars.isEmpty {
				SectionHeader("Wars")
				ForEach(wars) { WarCard(war: $0) }
			}

			if !tournaments.isEmpty {
				SectionHeader("Tournaments")
				ForEach(tournaments) { TournamentCard(tournament: $0) }
			}
		}
		.task { await load() }
	}

	func load() async {
		let api = model.api
		async let seasonPhase = api.phase(API.clubSeason(limit: 50))
		async let warsPhase = api.phase(API.clubWars())
		async let tournamentsPhase = api.phase(API.clubTournaments())

		if let fresh = await seasonPhase {
			withAnimation(Motion.popover) { season = fresh }
		}
		if case .loaded(let value) = await warsPhase { wars = value }
		if case .loaded(let value) = await tournamentsPhase { tournaments = value }
	}
}

struct ClubRow: View {

	let club: ClubCard

	var body: some View {
		HStack(spacing: Space.s3) {
			Text(verbatim: "\(club.place)")
				.font(.eraseNumber)
				.foregroundStyle(club.place <= 3 ? tierColor(club.place) : Palette.text3)
				.frame(width: 26, alignment: .trailing)

			ClubTag(tag: club.tag)

			VStack(alignment: .leading, spacing: 2) {
				Text(verbatim: club.name)
					.font(.eraseHeadline)
					.foregroundStyle(Palette.text)
				Text(verbatim: "\(club.members)/\(club.memberLimit) · \(club.wins)W \(club.losses)L")
					.font(.eraseSmallNumber)
					.foregroundStyle(Palette.text3)
			}

			Spacer(minLength: Space.s2)

			Text(verbatim: "\(club.elo)")
				.font(.eraseNumber.weight(.bold))
				.foregroundStyle(Palette.accentText)
		}
		.padding(Space.s3)
		.contentShape(.rect)
	}
}

struct ClubTag: View {

	let tag: String

	var body: some View {
		Text(verbatim: tag)
			.font(.eraseSmallNumber.weight(.bold))
			.foregroundStyle(Palette.accentText)
			.padding(.horizontal, 6)
			.padding(.vertical, 3)
			.background(Palette.accentSoft, in: .rect(cornerRadius: Radius.xs))
	}
}

private struct WarCard: View {

	let war: ClubWar

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			HStack {
				ModeIcon(Mode.of(war.mode), size: 18)
				Text(verbatim: Mode.of(war.mode).name)
					.font(.eraseFootnote.weight(.semibold))
				Spacer()
				Text(war.endedAt, format: .relative(presentation: .named))
					.font(.eraseCaption)
					.foregroundStyle(Palette.text3)
			}
			HStack {
				side(war.winner, won: true)
				Spacer()
				Text(verbatim: "±\(war.eloChange)")
					.font(.eraseSmallNumber)
					.foregroundStyle(Palette.text3)
				Spacer()
				side(war.loser, won: false)
			}
		}
		.panel(padding: Space.s3)
	}

	private func side(_ side: ClubWarSide, won: Bool) -> some View {
		NavigationLink(value: Route.club(side.name)) {
			VStack(alignment: won ? .leading : .trailing, spacing: 2) {
				Text(verbatim: side.name)
					.font(.eraseHeadline)
					.foregroundStyle(won ? Palette.win : Palette.loss)
				Text(verbatim: side.players.joined(separator: ", "))
					.font(.eraseCaption)
					.foregroundStyle(Palette.text3)
					.lineLimit(1)
			}
		}
		.buttonStyle(.pressable)
	}
}

private struct TournamentCard: View {

	let tournament: ClubTournament

	var body: some View {
		HStack(spacing: Space.s3) {
			Image(systemName: "trophy.fill")
				.foregroundStyle(Palette.gold)
				.font(.title3)
			VStack(alignment: .leading, spacing: 2) {
				Text(verbatim: tournament.championName)
					.font(.eraseHeadline)
				Text(verbatim: "\(Mode.of(tournament.mode).name) · \(tournament.clubs) · \(tournament.pot)")
					.font(.eraseSmallNumber)
					.foregroundStyle(Palette.text3)
			}
			Spacer()
			Text(tournament.endedAt, format: .dateTime.day().month())
				.font(.eraseCaption)
				.foregroundStyle(Palette.text3)
		}
		.panel(padding: Space.s3)
	}
}

struct ClubView: View {

	let name: String

	@Environment(AppModel.self) private var model

	@State private var phase: Phase<ClubProfile> = .loading

	var body: some View {
		ScrollView {
			LoadState(phase, retry: load) { profile in
				VStack(alignment: .leading, spacing: Space.s4) {
					HStack(spacing: Space.s3) {
						ClubTag(tag: profile.club.tag).scaleEffect(1.3)
						VStack(alignment: .leading) {
							Text(verbatim: profile.club.name).font(.eraseTitle2)
							if !profile.club.motto.isEmpty {
								Text(verbatim: profile.club.motto)
									.font(.eraseFootnote)
									.foregroundStyle(Palette.text2)
							}
						}
					}

					LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
						StatTile("Elo", value: "\(profile.club.elo)", tint: Palette.accentText)
						StatTile("Place", value: "#\(profile.club.place)")
						StatTile("Wars", value: "\(profile.warsWon)–\(profile.warsLost)")
						StatTile("Members", value: "\(profile.club.members)/\(profile.club.memberLimit)")
					}

					SectionHeader("Members")
					VStack(spacing: 0) {
						ForEach(profile.members, id: \.name) { member in
							NavigationLink(value: Route.player(member.name)) {
								HStack(spacing: Space.s3) {
									PlayerHead(member.name, size: 30)
									VStack(alignment: .leading, spacing: 2) {
										RankedName(member.name, rank: member.rank).font(.eraseHeadline)
										Text(verbatim: member.role.capitalized)
											.font(.eraseCaption)
											.foregroundStyle(member.role == "owner" ? Palette.gold : Palette.text3)
									}
									Spacer()
									Text(member.lastSeen, format: .relative(presentation: .named))
										.font(.eraseCaption)
										.foregroundStyle(Palette.text3)
								}
								.padding(Space.s3)
								.contentShape(.rect)
							}
							.buttonStyle(.pressable)
						}
					}
					.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
					.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))

					if !profile.seasons.isEmpty {
						SectionHeader("Seasons")
						ForEach(profile.seasons, id: \.season) { result in
							HStack {
								Text(verbatim: Copy.text("clubs.season", ["number": result.season]))
									.font(.eraseCallout.weight(.semibold))
								Spacer()
								Text(verbatim: "#\(result.place) · \(result.elo)")
									.font(.eraseNumber)
									.foregroundStyle(Palette.text2)
							}
							.panel(padding: Space.s3)
						}
					}
				}
				.padding(Space.s4)
			}
		}
		.background(Palette.background)
		.navigationTitle(name)
		.navigationBarTitleDisplayMode(.inline)
		.refreshable { await load() }
		.task { await load() }
	}

	private func load() async {
		if let fresh = await model.api.phase(API.club(name)) {
			withAnimation(Motion.popover) { phase = fresh }
		}
	}
}
