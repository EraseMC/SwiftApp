import Charts
import EraseKit
import EraseUI
import SwiftUI

/// One mode of one player: ranked and casual standing, the Elo chart and recent matches.
struct LadderView: View {

	let player: String

	let mode: ModeKey

	@Environment(AppModel.self) private var model

	@State private var ladder: Phase<LadderStats> = .loading

	@State private var history: [EloPoint] = []

	@State private var recent: [MatchEntry] = []

	@State private var range: ChartRange = .month

	enum ChartRange: String, CaseIterable, Identifiable {
		case week = "7D"
		case month = "30D"
		case quarter = "90D"
		case all = "All"

		var id: Self { self }

		var days: Int? {
			switch self {
			case .week: 7
			case .month: 30
			case .quarter: 90
			case .all: nil
			}
		}
	}

	var body: some View {
		ScrollView {
			LoadState(ladder, retry: load) { ladder in
				VStack(alignment: .leading, spacing: Space.s4) {
					HStack(spacing: Space.s3) {
						ModeIcon(Mode.of(mode), size: 44)
						VStack(alignment: .leading) {
							Text(verbatim: Mode.of(mode).name).font(.eraseTitle2)
							Text(verbatim: ladder.division.current)
								.font(.eraseFootnote.weight(.semibold))
								.foregroundStyle(Palette.accentText)
						}
					}

					LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
						StatTile("Elo", value: "\(ladder.elo)", tint: Palette.accentText)
						StatTile("Peak", value: "\(ladder.peak)")
						StatTile("Place", value: ladder.place.map { "#\($0)" } ?? "—")
						StatTile("Record", value: "\(ladder.wins)–\(ladder.losses)")
					}

					chart

					SectionHeader("Casual")
					LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
						StatTile("Wins", value: "\(ladder.casual.wins)", tint: Palette.casual)
						StatTile("Title", value: ladder.casual.division.current)
					}

					if !recent.isEmpty {
						SectionHeader("Recent matches") {
							NavigationLink(value: Route.playerMatches(player)) {
								Text("All").font(.eraseFootnote.weight(.semibold))
							}
						}
						VStack(spacing: 0) {
							ForEach(recent) { match in
								NavigationLink(value: Route.match(match.id, perspective: player)) {
									MatchRow(match: match).padding(.horizontal, Space.s3).padding(.vertical, Space.s1)
								}
								.buttonStyle(.pressable)
							}
						}
						.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
					}
				}
				.padding(Space.s4)
			}
		}
		.background(Palette.background)
		.navigationTitle(player)
		.navigationBarTitleDisplayMode(.inline)
		.refreshable { await load() }
		.task { await load() }
	}

	@ViewBuilder
	private var chart: some View {
		let points = visiblePoints
		VStack(alignment: .leading, spacing: Space.s3) {
			HStack {
				Text("Elo history").font(.eraseTitle3)
				Spacer()
				PillPicker(selection: $range, options: ChartRange.allCases) { range in
					Text(LocalizedStringKey(range.rawValue))
				}
			}

			if points.count < 2 {
				Text("Not enough ranked games in this period.")
					.font(.eraseFootnote)
					.foregroundStyle(Palette.text3)
					.frame(maxWidth: .infinity, minHeight: 160)
			} else {
				Chart(points, id: \.endedAt) { point in
					AreaMark(x: .value("Date", point.endedAt), y: .value("Elo", point.elo))
						.foregroundStyle(LinearGradient(colors: [Palette.accent.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom))
						.interpolationMethod(.monotone)
					LineMark(x: .value("Date", point.endedAt), y: .value("Elo", point.elo))
						.foregroundStyle(Palette.accent)
						.lineStyle(StrokeStyle(lineWidth: 2))
						.interpolationMethod(.monotone)
				}
				.chartYScale(domain: .automatic(includesZero: false))
				.chartXAxis {
					AxisMarks(values: .automatic(desiredCount: 4)) {
						AxisValueLabel(format: .dateTime.day().month(.abbreviated))
					}
				}
				.frame(height: 180)
				.animation(Motion.scope, value: range)
			}
		}
		.panel()
	}

	private var visiblePoints: [EloPoint] {
		guard let days = range.days else { return history }
		let from = Date.now.addingTimeInterval(-Double(days) * 86_400)
		return history.filter { $0.endedAt >= from }
	}

	private func load() async {
		let api = model.api
		async let ladderPhase = api.phase(API.ladder(player, mode: mode))
		async let historyPhase = api.phase(API.eloHistory(player, mode: mode, limit: 500))
		async let recentPhase = api.phase(API.matches(player, mode: mode, limit: 5))

		if let fresh = await ladderPhase {
			withAnimation(Motion.popover) { ladder = fresh }
		}
		if case .loaded(let points) = await historyPhase { history = points.sorted { $0.endedAt < $1.endedAt } }
		if case .loaded(let matches) = await recentPhase { recent = matches }
	}
}
