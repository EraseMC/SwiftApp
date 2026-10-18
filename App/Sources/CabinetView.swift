import Charts
import EraseKit
import EraseUI
import SwiftUI

/// The signed-in player's private cabinet, as on erasemc.com/account.
struct CabinetView: View {

	let player: String

	@Environment(AppModel.self) private var model

	@State private var insights: Phase<AccountInsights> = .loading

	@State private var profile: PlayerProfile?

	var body: some View {
		LoadState(insights, retry: load) { insights in
			VStack(alignment: .leading, spacing: Space.s4) {
				header(insights)
				headline(insights)
				activity(insights.activity)
				modes(insights.modes)
				averages(insights.averages)
				if let profile {
					ladders(profile.ladders.filter(\.played))
				}
				opponents(insights.opponents)
				streaks(insights.lifetime)
			}
		}
		.task { await load() }
	}

	private func header(_ insights: AccountInsights) -> some View {
		HStack(spacing: Space.s3) {
			PlayerHead(player, size: 56)
			VStack(alignment: .leading, spacing: 2) {
				if let rank = profile?.player.rank {
					RankedName(player, rank: rank).font(.eraseTitle2)
				} else {
					Text(verbatim: player).font(.eraseTitle2)
				}
				Label(Copy.text("cab.linked"), systemImage: "checkmark.seal.fill")
					.font(.eraseFootnote)
					.foregroundStyle(Palette.win)
			}
			Spacer()
			NavigationLink(value: Route.player(player)) {
				Text(Copy.text("cab.openProfile")).font(.eraseFootnote.weight(.semibold))
			}
		}
	}

	private func headline(_ insights: AccountInsights) -> some View {
		let lifetime = insights.lifetime
		let games = lifetime.wins + lifetime.losses
		let kd = lifetime.deaths == 0 ? Double(lifetime.kills) : Double(lifetime.kills) / Double(lifetime.deaths)

		return LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
			StatTile(LocalizedStringKey(Copy.text("cab.coins").capitalized), value: insights.coins.formatted(), tint: Palette.gold)
			StatTile(LocalizedStringKey(Copy.text("cab.globalElo")), value: profile?.ranked.elo.map(String.init) ?? "—", tint: Palette.accentText)
			StatTile(LocalizedStringKey(Copy.text("cab.serverPlace")), value: profile?.ranked.place.map { "#\($0)" } ?? "—")
			StatTile(LocalizedStringKey(Copy.text("cab.matches")), value: games.formatted())
			StatTile(LocalizedStringKey(Copy.text("cab.playTime")), value: Copy.text("cab.hours", ["value": lifetime.playTime / 3600]))
			StatTile(LocalizedStringKey(Copy.text("cab.kd")), value: kd.formatted(.number.precision(.fractionLength(2))))
		}
	}

	private func activity(_ days: [AccountInsights.ActivityDay]) -> some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("cab.activity")).font(.eraseTitle3)
			if days.allSatisfy({ $0.games == 0 }) {
				Text(Copy.text("cab.noActivity")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			} else {
				Chart(days, id: \.day) { day in
					BarMark(x: .value("Day", day.day), y: .value("Games", day.games))
						.foregroundStyle(Palette.surfaceActive)
					BarMark(x: .value("Day", day.day), y: .value("Wins", day.wins))
						.foregroundStyle(Palette.accent)
				}
				.chartXAxis(.hidden)
				.frame(height: 120)
				Text(Copy.text("cab.activityNote")).font(.eraseCaption).foregroundStyle(Palette.text3)
			}
		}
		.panel()
	}

	private func modes(_ shares: [AccountInsights.ModeShare]) -> some View {
		let total = max(1, shares.reduce(0) { $0 + $1.games })
		return VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("cab.modes")).font(.eraseTitle3)
			ForEach(shares.prefix(6), id: \.mode) { share in
				let mode = Mode.of(share.mode)
				VStack(alignment: .leading, spacing: Space.s1) {
					HStack {
						ModeIcon(mode, size: 20)
						Text(verbatim: mode.name).font(.eraseFootnote.weight(.semibold))
						Spacer()
						Text(Copy.text("cab.games", ["count": share.games]))
							.font(.eraseSmallNumber)
							.foregroundStyle(Palette.text3)
					}
					ProgressView(value: Double(share.games), total: Double(total)).tint(Palette.accent)
				}
			}
			Text(Copy.text("cab.modesNote")).font(.eraseCaption).foregroundStyle(Palette.text3)
		}
		.panel()
	}

	private func averages(_ averages: AccountInsights.Averages) -> some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("cab.averages")).font(.eraseTitle3)
			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: 3), spacing: Space.s2) {
				average("cab.avgHits", averages.hits.formatted(.number.precision(.fractionLength(1))))
				average("cab.avgCriticals", averages.criticals.formatted(.number.precision(.fractionLength(1))))
				average("cab.avgDamage", averages.damage.formatted(.number.precision(.fractionLength(0))))
				average("cab.avgAccuracy", averages.potionAccuracy.map { $0.formatted(.number.precision(.fractionLength(0))) + "%" } ?? "—")
				average("cab.avgDuration", Duration.seconds(averages.duration).formatted(.time(pattern: .minuteSecond)))
				average("cab.bestCombo", "\(averages.bestCombo)")
			}
			Text(Copy.text("cab.averagesNote", ["count": averages.matches]))
				.font(.eraseCaption)
				.foregroundStyle(Palette.text3)
		}
		.panel()
	}

	private func average(_ key: String, _ value: String) -> some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(Copy.text(key)).font(.eraseCaption).foregroundStyle(Palette.text3).lineLimit(1).minimumScaleFactor(0.8)
			Text(verbatim: value).font(.eraseNumber.weight(.bold))
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(Space.s2)
		.background(Palette.sunken, in: .rect(cornerRadius: Radius.sm))
	}

	private func ladders(_ ladders: [LadderStats]) -> some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("cab.ladders")).font(.eraseTitle3)
			if ladders.isEmpty {
				Text(Copy.text("cab.notPlayed")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			}
			ForEach(ladders, id: \.mode) { ladder in
				NavigationLink(value: Route.ladder(player: player, mode: ladder.mode)) {
					VStack(alignment: .leading, spacing: Space.s1) {
						HStack {
							ModeIcon(Mode.of(ladder.mode), size: 20)
							Text(verbatim: Mode.of(ladder.mode).name).font(.eraseFootnote.weight(.semibold))
							Spacer()
							Text(verbatim: "\(ladder.elo)").font(.eraseNumber.weight(.bold)).foregroundStyle(Palette.accentText)
						}
						ProgressView(value: Double(ladder.division.percent), total: 100).tint(Palette.accent)
						Text(ladder.division.winsToNext > 0
							? Copy.text("cab.toNext", ["wins": ladder.division.winsToNext, "division": ladder.division.next])
							: Copy.text("cab.topDivision"))
							.font(.eraseCaption)
							.foregroundStyle(Palette.text3)
					}
				}
				.buttonStyle(.pressable)
				.foregroundStyle(Palette.text)
			}
		}
		.panel()
	}

	private func opponents(_ opponents: [AccountInsights.Opponent]) -> some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("cab.opponents")).font(.eraseTitle3)
			if opponents.isEmpty {
				Text(Copy.text("cab.noOpponents")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			}
			ForEach(opponents.prefix(5), id: \.name) { opponent in
				NavigationLink(value: Route.player(opponent.name)) {
					HStack(spacing: Space.s3) {
						PlayerHead(opponent.name, size: 28)
						Text(verbatim: opponent.name).font(.eraseCallout.weight(.semibold))
						Spacer()
						Text(Copy.text("cab.record", ["wins": opponent.wins, "losses": opponent.games - opponent.wins]))
							.font(.eraseSmallNumber)
							.foregroundStyle(Palette.text3)
					}
				}
				.buttonStyle(.pressable)
				.foregroundStyle(Palette.text)
			}
		}
		.panel()
	}

	private func streaks(_ lifetime: AccountInsights.Lifetime) -> some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			Text(Copy.text("cab.streaks")).font(.eraseTitle3)
			HStack(spacing: Space.s3) {
				StatTile("Wins", value: "\(lifetime.winStreak)", tint: Palette.win)
				StatTile("Kills", value: "\(lifetime.killStreak)", tint: Palette.loss)
				StatTile("Days", value: "\(lifetime.dailyStreak)", tint: Palette.gold)
			}
		}
	}

	private func load() async {
		let api = model.api
		async let insightsPhase = api.phase(API.accountInsights)
		async let profilePhase = api.phase(API.player(player))

		if case .loaded(let value) = await profilePhase { profile = value }
		if let fresh = await insightsPhase {
			withAnimation(Motion.popover) { insights = fresh }
		}
	}
}
