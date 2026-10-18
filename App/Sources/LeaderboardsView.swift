import EraseKit
import EraseUI
import SwiftUI

struct LeaderboardsView: View {

	@Environment(AppModel.self) private var model

	@AppStorage("leaderboards.board") private var board = "global"

	@AppStorage("leaderboards.queue") private var queue: Queue = .ranked

	@AppStorage("leaderboards.scope") private var scope: Scope = .players

	@State private var phase: Phase<Leaderboard> = .loading

	enum Scope: String, CaseIterable {
		case players
		case clubs
	}

	/// Bumped by pull-to-refresh to rebuild the clubs section.
	@State private var clubsRefresh = 0

	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: Space.s3, pinnedViews: .sectionHeaders) {
				switch scope {
				case .players:
					Section {
						players
					} header: {
						filters
					}
				case .clubs:
					ClubsSection().id(clubsRefresh)
				}
			}
			.padding(.horizontal, Space.s4)
			.padding(.bottom, Space.s6)
			.readableWidth()
		}
		.background(Palette.background)
		.navigationTitle("Leaderboards")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				Picker("Scope", selection: $scope) {
					Text("Players").tag(Scope.players)
					Text(Copy.text("nav.clubs")).tag(Scope.clubs)
				}
				.pickerStyle(.segmented)
				.frame(width: 220)
			}
		}
		.refreshable {
			if scope == .players {
				await load()
			} else {
				clubsRefresh += 1
			}
		}
		.task(id: "\(board)|\(queue.rawValue)") { await load() }
	}

	private var players: some View {
		LoadState(phase, retry: load) { leaderboard in
			if leaderboard.entries.isEmpty {
				ContentUnavailableView("No players yet", systemImage: "trophy")
			} else {
				VStack(spacing: 0) {
					ForEach(leaderboard.entries, id: \.place) { entry in
						NavigationLink(value: Route.player(entry.name)) {
							LadderRow(entry: entry, queue: leaderboard.queue)
						}
						.buttonStyle(.pressable)
						if entry.place != leaderboard.entries.last?.place {
							Divider().overlay(Palette.line).padding(.leading, 72)
						}
					}
				}
				.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
				.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))
			}
		}
	}

	private var filters: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			ScrollView(.horizontal) {
				HStack(spacing: Space.s2) {
					BoardChip(title: Text("Global"), icon: nil, selected: board == "global") { board = "global" }
					ForEach(Mode.ladders) { mode in
						BoardChip(title: Text(verbatim: mode.name), icon: mode, selected: board == mode.key.rawValue) {
							board = mode.key.rawValue
						}
					}
				}
				.scrollTargetLayout()
			}
			.scrollIndicators(.hidden)
			.scrollTargetBehavior(.viewAligned)
			.contentMargins(.horizontal, Space.s4, for: .scrollContent)
			.padding(.horizontal, -Space.s4)

			PillPicker(selection: $queue, options: Queue.allCases) { queue in
				Text(queue == .ranked ? "Ranked" : "Casual")
			}
		}
		.padding(.vertical, Space.s2)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Palette.background)
		.sensoryFeedback(.selection, trigger: board)
	}

	private func load() async {
		if phase.value?.board != board || phase.value?.queue != queue {
			phase = .loading
		}
		if let fresh = await model.api.phase(API.leaderboard(board, queue: queue)) {
			withAnimation(Motion.popover) { phase = fresh }
		}
	}
}

private struct BoardChip: View {

	let title: Text

	let icon: Mode?

	let selected: Bool

	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: Space.s2) {
				if let icon {
					ModeIcon(icon, size: 18)
				} else {
					Image(systemName: "globe")
						.font(.footnote.weight(.semibold))
				}
				title
					.font(.eraseFootnote.weight(.semibold))
			}
			.foregroundStyle(selected ? Palette.text : Palette.text2)
			.padding(.horizontal, Space.s3)
			.padding(.vertical, Space.s2)
			.background(selected ? Palette.accentSoft : Palette.surface, in: .capsule)
			.overlay(Capsule().strokeBorder(selected ? Palette.accent.opacity(0.5) : Palette.line))
		}
		.buttonStyle(.pressable)
		.accessibilityAddTraits(selected ? .isSelected : [])
	}
}

private struct LadderRow: View {

	let entry: LadderEntry

	let queue: Queue

	var body: some View {
		HStack(spacing: Space.s3) {
			Text(verbatim: "\(entry.place)")
				.font(.eraseNumber)
				.foregroundStyle(placeColor)
				.frame(width: 28, alignment: .trailing)

			PlayerHead(entry.name, size: 32)

			VStack(alignment: .leading, spacing: 2) {
				RankedName(entry.name, rank: entry.rank)
					.font(.eraseHeadline)
				Text(verbatim: "\(entry.wins)W · \(entry.losses)L")
					.font(.eraseSmallNumber)
					.foregroundStyle(Palette.text3)
			}

			Spacer(minLength: Space.s2)

			VStack(alignment: .trailing, spacing: 2) {
				Text(verbatim: entry.elo.map(String.init) ?? "\(entry.wins)")
					.font(.eraseNumber.weight(.bold))
					.foregroundStyle(Palette.text)
				Text(queue == .ranked ? "Elo" : "Wins")
					.font(.eraseCaption)
					.foregroundStyle(Palette.text3)
			}
		}
		.padding(.horizontal, Space.s3)
		.padding(.vertical, Space.s3)
		.contentShape(.rect)
		.accessibilityElement(children: .combine)
	}

	private var placeColor: Color {
		switch entry.place {
		case 1: Palette.gold
		case 2: Palette.silver
		case 3: Palette.bronze
		default: Palette.text3
		}
	}
}
