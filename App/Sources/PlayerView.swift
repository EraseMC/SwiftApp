import EraseKit
import EraseUI
import SwiftUI

struct PlayerView: View {

	let name: String

	@Environment(AppModel.self) private var model

	@Environment(Favorites.self) private var favorites

	@AppStorage("profile.queue") private var queue: Queue = .ranked

	@State private var phase: Phase<PlayerProfile> = .loading

	@State private var recent: [MatchEntry] = []

	@State private var tiers: [TierPlacement] = []

	var body: some View {
		ScrollView {
			LoadState(phase, retry: load) { profile in
				VStack(alignment: .leading, spacing: Space.s4) {
					header(profile)

					PillPicker(selection: $queue, options: Queue.allCases) { queue in
						Text(queue == .ranked ? "Ranked" : "Casual")
					}

					summary(profile.summary(for: queue))

					if !tiers.isEmpty {
						ScrollView(.horizontal) {
							HStack(spacing: Space.s2) {
								ForEach(tiers) { placement in
									HStack(spacing: Space.s1) {
										ModeIcon(Mode.of(placement.board), size: 18)
										TierChip(label: placement.label, level: placement.level, inactive: placement.inactive)
										Text(verbatim: placement.platform.rawValue.uppercased())
											.font(.eraseCaption)
											.foregroundStyle(Palette.text3)
									}
									.padding(.horizontal, Space.s3)
									.padding(.vertical, Space.s2)
									.background(Palette.surface, in: .capsule)
									.overlay(Capsule().strokeBorder(Palette.line))
								}
							}
						}
						.scrollIndicators(.hidden)
					}

					SectionHeader("Duels")
					LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: Space.s3)], spacing: Space.s3) {
						ForEach(profile.ladders.filter { queue == .ranked ? $0.played : $0.casual.games > 0 }, id: \.mode) { ladder in
							NavigationLink(value: Route.ladder(player: profile.player.name, mode: ladder.mode)) {
								LadderCard(ladder: ladder, queue: queue)
							}
							.buttonStyle(.pressable)
						}
					}

					SectionHeader("Recent matches") {
						NavigationLink(value: Route.playerMatches(profile.player.name)) {
							Text("All").font(.eraseFootnote.weight(.semibold))
						}
					}
					if recent.isEmpty {
						Text("No matches yet")
							.font(.eraseFootnote)
							.foregroundStyle(Palette.text3)
					} else {
						VStack(spacing: 0) {
							ForEach(recent) { match in
								NavigationLink(value: Route.match(match.id, perspective: profile.player.name)) {
									MatchRow(match: match)
										.padding(.horizontal, Space.s3)
										.padding(.vertical, Space.s1)
								}
								.buttonStyle(.pressable)
							}
						}
						.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
						.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))
					}

					if let club = profile.club {
						SectionHeader(LocalizedStringKey(Copy.text("nav.clubs")))
						NavigationLink(value: Route.club(club.name)) {
							HStack(spacing: Space.s3) {
								ClubTag(tag: club.tag)
								Text(verbatim: club.name).font(.eraseHeadline).foregroundStyle(Palette.text)
								Spacer()
								Text(verbatim: club.role.capitalized)
									.font(.eraseFootnote)
									.foregroundStyle(Palette.text3)
								Image(systemName: "chevron.right")
									.font(.footnote.weight(.semibold))
									.foregroundStyle(Palette.text3)
							}
							.panel(padding: Space.s3)
						}
						.buttonStyle(.pressable)
					}

					if !profile.friends.isEmpty {
						SectionHeader("Friends")
						ScrollView(.horizontal) {
							HStack(spacing: Space.s3) {
								ForEach(profile.friends, id: \.name) { friend in
									NavigationLink(value: Route.player(friend.name)) {
										VStack(spacing: Space.s1) {
											PlayerHead(friend.name, size: 48)
											RankedName(friend.name, rank: friend.rank)
												.font(.eraseCaption)
												.frame(maxWidth: 72)
										}
									}
									.buttonStyle(.pressable)
								}
							}
						}
						.scrollIndicators(.hidden)
					}
				}
				.padding(Space.s4)
				.readableWidth()
			}
		}
		.background(Palette.background)
		.navigationTitle(name)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					favorites.toggle(phase.value?.player.name ?? name)
				} label: {
					Label("Favorite", systemImage: favorites.contains(name) ? "star.fill" : "star")
				}
				.sensoryFeedback(.success, trigger: favorites.contains(name))
			}
			ToolbarItem(placement: .topBarTrailing) {
				ShareLink(item: profileURL)
			}
		}
		.userActivity("com.erasemc.app.player") { activity in
			// Handoff: the same profile opens on a Mac or another device in the browser.
			activity.title = name
			activity.webpageURL = profileURL
			activity.isEligibleForHandoff = true
		}
		.refreshable { await load() }
		.task { await load() }
	}

	private var profileURL: URL {
		URL(string: "https://erasemc.com/profile/\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name)")!
	}

	private func header(_ profile: PlayerProfile) -> some View {
		HStack(spacing: Space.s4) {
			PlayerHead(profile.player.name, size: 72)

			VStack(alignment: .leading, spacing: Space.s1) {
				RankedName(profile.player.name, rank: profile.player.rank)
					.font(.eraseTitle2)
				Text(verbatim: profile.player.rank.displayName)
					.font(.eraseFootnote.weight(.semibold))
					.foregroundStyle(profile.player.rank.tint)
				presence(profile.presence)
			}
			Spacer(minLength: 0)
		}
	}

	@ViewBuilder
	private func presence(_ presence: PlayerPresence) -> some View {
		HStack(spacing: Space.s1) {
			Circle()
				.fill(presence.online == true ? Palette.win : Palette.text3)
				.frame(width: 7, height: 7)
			if presence.online == true {
				Text("Online")
			} else {
				Text("Last seen \(presence.lastSeen, format: .relative(presentation: .named))")
			}
		}
		.font(.eraseFootnote)
		.foregroundStyle(Palette.text2)
	}

	private func summary(_ summary: QueueSummary) -> some View {
		LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
			if let elo = summary.elo {
				StatTile("Global Elo", value: "\(elo)", tint: Palette.accentText)
			} else {
				StatTile("Wins", value: "\(summary.wins)", tint: Palette.casual)
			}
			StatTile("Place", value: summary.place.map { "#\($0)" } ?? "—")
			StatTile("Record", value: "\(summary.wins)–\(summary.losses)")
			StatTile("Win rate", value: summary.winRate.formatted(.number.precision(.fractionLength(0...1))) + "%")
		}
	}

	private func load() async {
		let api = model.api
		async let profilePhase = api.phase(API.player(name))
		async let recentPhase = api.phase(API.matches(name, limit: 5))
		async let tiersPhase = api.phase(API.playerTiers(name))

		if let fresh = await profilePhase {
			withAnimation(Motion.popover) { phase = fresh }
			if let profile = fresh.value {
				PlayerSpotlight.index(profile)
			}
		}
		if case .loaded(let matches) = await recentPhase {
			recent = matches
		}
		if case .loaded(let found) = await tiersPhase {
			tiers = found.placements
		}
	}
}

private struct LadderCard: View {

	let ladder: LadderStats

	let queue: Queue

	var body: some View {
		let mode = Mode.of(ladder.mode)
		let division = queue == .ranked ? ladder.division : ladder.casual.division

		VStack(alignment: .leading, spacing: Space.s2) {
			HStack(spacing: Space.s2) {
				ModeIcon(mode, size: 22)
				Text(verbatim: mode.name)
					.font(.eraseFootnote.weight(.semibold))
					.foregroundStyle(Palette.text)
					.lineLimit(1)
			}

			Text(verbatim: queue == .ranked ? "\(ladder.elo)" : "\(ladder.casual.wins)")
				.font(.eraseStat)
				.foregroundStyle(queue == .ranked ? Palette.accentText : Palette.casual)

			Text(verbatim: division.current)
				.font(.eraseCaption)
				.foregroundStyle(Palette.text3)

			ProgressView(value: Double(division.percent), total: 100)
				.tint(queue == .ranked ? Palette.accent : Palette.casual)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.panel(padding: Space.s3)
	}
}
