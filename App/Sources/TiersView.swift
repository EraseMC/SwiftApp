import EraseKit
import EraseUI
import SwiftUI

struct TiersView: View {

	@Environment(AppModel.self) private var model

	/// `overall` or a tier mode key.
	@AppStorage("tiers.board") private var board = "overall"

	@AppStorage("tiers.platform") private var platform: TierPlatform = .pc

	@State private var overall: Phase<TierOverall> = .loading

	@State private var boardPhase: Phase<TierBoard> = .loading

	@State private var selected: TierPlacement?

	@State private var showsInformation = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: Space.s4) {
				filters

				if board == "overall" {
					LoadState(overall, retry: load) { overall in
						OverallList(overall: overall)
					}
				} else {
					LoadState(boardPhase, retry: load) { board in
						BoardColumns(board: board) { selected = $0 }
					}
				}
			}
			.padding(Space.s4)
		}
		.background(Palette.background)
		.navigationTitle(Copy.text("nav.tiers"))
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					showsInformation = true
				} label: {
					Label(Copy.text("tiers.information"), systemImage: "info.circle")
				}
			}
		}
		.refreshable { await load() }
		.task(id: "\(board)|\(platform.rawValue)") { await load() }
		.sheet(item: $selected) { placement in
			PlacementSheet(placement: placement)
				.presentationDetents([.medium, .large])
		}
		.sheet(isPresented: $showsInformation) {
			TierInformationSheet()
				.presentationDetents([.large])
		}
	}

	private var filters: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			ScrollView(.horizontal) {
				HStack(spacing: Space.s2) {
					chip(Text(Copy.text("tiers.overall")), mode: nil, key: "overall")
					ForEach(Mode.tiers) { mode in
						chip(Text(verbatim: mode.name), mode: mode, key: mode.key.rawValue)
					}
				}
			}
			.scrollIndicators(.hidden)

			HStack(spacing: Space.s3) {
				PillPicker(selection: $platform, options: TierPlatform.allCases) { platform in
					Text(verbatim: platform.rawValue.uppercased())
				}
				Text(Copy.text(platform == .pc ? "tiers.leaguePc" : "tiers.leaguePe"))
					.font(.eraseFootnote)
					.foregroundStyle(Palette.text3)
					.lineLimit(2)
			}
		}
	}

	private func chip(_ title: Text, mode: Mode?, key: String) -> some View {
		let isSelected = board == key
		return Button {
			board = key
		} label: {
			HStack(spacing: Space.s2) {
				if let mode {
					ModeIcon(mode, size: 18)
				} else {
					Image(systemName: "square.grid.2x2.fill").font(.footnote)
				}
				title.font(.eraseFootnote.weight(.semibold))
			}
			.foregroundStyle(isSelected ? Palette.text : Palette.text2)
			.padding(.horizontal, Space.s3)
			.padding(.vertical, Space.s2)
			.background(isSelected ? Palette.accentSoft : Palette.surface, in: .capsule)
			.overlay(Capsule().strokeBorder(isSelected ? Palette.accent.opacity(0.5) : Palette.line))
		}
		.buttonStyle(.pressable)
		.sensoryFeedback(.selection, trigger: isSelected)
	}

	private func load() async {
		if board == "overall" {
			if overall.value?.platform != platform { overall = .loading }
			if let fresh = await model.api.phase(API.tierOverall(platform: platform)) {
				withAnimation(Motion.popover) { overall = fresh }
			}
		} else {
			let mode = ModeKey(rawValue: board)
			if boardPhase.value?.board != mode || boardPhase.value?.platform != platform { boardPhase = .loading }
			if let fresh = await model.api.phase(API.tierBoard(mode, platform: platform)) {
				withAnimation(Motion.popover) { boardPhase = fresh }
			}
		}
	}
}

/// Gold, silver, bronze for the top three tiers, quiet text below, as on the site.
func tierColor(_ level: Int) -> Color {
	switch level {
	case 1: Palette.gold
	case 2: Palette.silver
	case 3: Palette.bronze
	default: Palette.text2
	}
}

struct TierChip: View {

	let label: String

	let level: Int

	var inactive = false

	var body: some View {
		Text(verbatim: label)
			.font(.eraseSmallNumber.weight(.bold))
			.foregroundStyle(tierColor(level))
			.padding(.horizontal, 6)
			.padding(.vertical, 2)
			.background(tierColor(level).opacity(0.14), in: .rect(cornerRadius: Radius.xs))
			.opacity(inactive ? 0.45 : 1)
	}
}

private struct BoardColumns: View {

	let board: TierBoard

	let select: (TierPlacement) -> Void

	var body: some View {
		VStack(spacing: Space.s3) {
			ForEach(board.columns, id: \.level) { column in
				VStack(alignment: .leading, spacing: 0) {
					HStack {
						Text(verbatim: "\(Copy.text("tiers.tier")) \(column.level)")
							.font(.eraseHeadline)
							.foregroundStyle(tierColor(column.level))
						Spacer()
						Text(verbatim: "\(column.players.count)")
							.font(.eraseSmallNumber)
							.foregroundStyle(Palette.text3)
					}
					.padding(Space.s3)

					if column.players.isEmpty {
						Text(verbatim: "—")
							.font(.eraseFootnote)
							.foregroundStyle(Palette.text3)
							.padding([.horizontal, .bottom], Space.s3)
					}

					ForEach(column.players) { placement in
						Button { select(placement) } label: {
							PlacementRow(placement: placement)
						}
						.buttonStyle(.pressable)
					}
				}
				.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
				.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))
			}
		}
	}
}

private struct PlacementRow: View {

	let placement: TierPlacement

	var body: some View {
		HStack(spacing: Space.s3) {
			PlayerHead(placement.name, size: 28)
			RankedName(placement.name, rank: placement.rank)
				.font(.eraseCallout.weight(.semibold))
			Spacer(minLength: Space.s2)
			switch placement.movement {
			case .up:
				Image(systemName: "chevron.up").foregroundStyle(Palette.win).font(.caption.weight(.bold))
			case .down:
				Image(systemName: "chevron.down").foregroundStyle(Palette.loss).font(.caption.weight(.bold))
			case .none:
				EmptyView()
			}
			TierChip(label: placement.label, level: placement.level, inactive: placement.inactive)
		}
		.padding(.horizontal, Space.s3)
		.padding(.vertical, Space.s2)
		.opacity(placement.inactive ? 0.6 : 1)
		.contentShape(.rect)
	}
}

private struct OverallList: View {

	let overall: TierOverall

	var body: some View {
		if overall.players.isEmpty {
			ContentUnavailableView(Copy.text("tiers.overall"), systemImage: "chart.bar", description: Text(Copy.text("tiers.overallEmpty")))
		} else {
			VStack(spacing: 0) {
				ForEach(overall.players, id: \.position) { standing in
					NavigationLink(value: Route.player(standing.name)) {
						HStack(spacing: Space.s3) {
							Text(verbatim: "\(standing.position)")
								.font(.eraseNumber)
								.foregroundStyle(standing.position <= 3 ? tierColor(standing.position) : Palette.text3)
								.frame(width: 26, alignment: .trailing)
							PlayerHead(standing.name, size: 32)
							VStack(alignment: .leading, spacing: Space.s1) {
								RankedName(standing.name, rank: standing.rank)
									.font(.eraseHeadline)
								HStack(spacing: Space.s1) {
									ForEach(standing.tiers, id: \.board) { badge in
										HStack(spacing: 3) {
											ModeIcon(Mode.of(badge.board), size: 14)
											TierChip(label: badge.label, level: badge.level, inactive: badge.inactive)
										}
									}
								}
							}
							Spacer(minLength: Space.s2)
							Text(verbatim: "\(standing.points)")
								.font(.eraseNumber.weight(.bold))
								.foregroundStyle(Palette.accentText)
						}
						.padding(Space.s3)
						.contentShape(.rect)
					}
					.buttonStyle(.pressable)
				}
			}
			.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
			.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))
		}
	}
}

/// The placement card the site opens on click: who tested, the grades and where the player came from.
private struct PlacementSheet: View {

	let placement: TierPlacement

	@Environment(AppModel.self) private var model

	@Environment(\.dismiss) private var dismiss

	private static let criteria: [ModeKey: [String]] = [
		.noDebuff: ["aim", "movement", "potting", "sense"],
		.boxing: ["aim", "movement", "combo", "sense"],
		.sumo: ["aim", "movement", "edge", "sense"],
	]

	var body: some View {
		NavigationStack {
			List {
				Section {
					HStack(spacing: Space.s3) {
						PlayerHead(placement.name, size: 48)
						VStack(alignment: .leading) {
							RankedName(placement.name, rank: placement.rank).font(.eraseTitle3)
							Text(verbatim: placement.rank.displayName)
								.font(.eraseFootnote)
								.foregroundStyle(placement.rank.tint)
						}
						Spacer()
						TierChip(label: placement.label, level: placement.level, inactive: placement.inactive)
							.scaleEffect(1.3)
					}
					if placement.inactive {
						Text(Copy.text("tiers.inactive"))
							.font(.eraseFootnote)
							.foregroundStyle(Palette.warn)
					}
				}

				Section {
					LabeledContent(Copy.text("tiers.mode"), value: Mode.of(placement.board).name)
					if let test = placement.test {
						LabeledContent(Copy.text("tiers.tester"), value: test.tester)
						LabeledContent(Copy.text("tiers.tested")) {
							Text(test.createdAt, format: .dateTime.day().month().year())
						}
						LabeledContent(Copy.text("tiers.series"), value: "\(test.playerScore) – \(test.testerScore)")
						LabeledContent(Copy.text("tiers.previous")) {
							if let level = test.previousLevel, let band = test.previousBand {
								TierChip(label: "\(band.rawValue)\(level)", level: level)
							} else {
								Text(Copy.text("tiers.firstTier"))
							}
						}
					} else {
						Text(Copy.text("tiers.byHand")).foregroundStyle(Palette.text2)
					}
				}

				if let test = placement.test, let names = Self.criteria[placement.board] {
					Section {
						ForEach(Array(zip(names, test.grades)), id: \.0) { name, grade in
							HStack {
								Text(Copy.text("staff.criterion.\(name)"))
								Spacer()
								GradeBar(grade: grade)
							}
						}
					}
				}

				Section {
					Button(Copy.text("tiers.viewProfile")) {
						dismiss()
						model.open(.player(placement.name))
					}
					.frame(maxWidth: .infinity)
				}
			}
			.font(.eraseCallout)
			.navigationTitle(placement.name)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

private struct GradeBar: View {

	let grade: Int

	var body: some View {
		HStack(spacing: 3) {
			ForEach(1...5, id: \.self) { step in
				Capsule()
					.fill(step <= grade ? Palette.accent : Palette.surfaceActive)
					.frame(width: 14, height: 6)
			}
		}
		.accessibilityLabel(Text(verbatim: "\(grade)/5"))
	}
}

private struct TierInformationSheet: View {

	private static let points: [(String, Int, Int)] = [
		("HT1", 1, 60), ("LT1", 1, 45), ("HT2", 2, 30), ("LT2", 2, 20), ("HT3", 3, 10),
		("LT3", 3, 6), ("HT4", 4, 4), ("LT4", 4, 3), ("HT5", 5, 2), ("LT5", 5, 1),
	]

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: Space.s5) {
					block("tiers.info.howHeading", "tiers.info.howBody")
					block("tiers.info.leaguesHeading", "tiers.info.leaguesBody")
					block("tiers.info.inactiveHeading", "tiers.info.inactiveBody")

					VStack(alignment: .leading, spacing: Space.s3) {
						Text(Copy.text("tiers.info.pointsHeading")).font(.eraseTitle3)
						LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: 5), spacing: Space.s2) {
							ForEach(Self.points, id: \.0) { label, level, points in
								VStack(spacing: Space.s1) {
									TierChip(label: label, level: level)
									Text(verbatim: "\(points)")
										.font(.eraseSmallNumber)
										.foregroundStyle(Palette.text2)
								}
								.frame(maxWidth: .infinity)
								.padding(.vertical, Space.s2)
								.background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
							}
						}
						Text(Copy.text("tiers.info.pointsNote"))
							.font(.eraseFootnote)
							.foregroundStyle(Palette.text3)
					}
				}
				.padding(Space.s4)
			}
			.background(Palette.background)
			.navigationTitle(Copy.text("tiers.information"))
			.navigationBarTitleDisplayMode(.inline)
		}
	}

	private func block(_ heading: String, _ body: String) -> some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			Text(Copy.text(heading)).font(.eraseTitle3).foregroundStyle(Palette.text)
			Text(Copy.text(body)).font(.eraseCallout).foregroundStyle(Palette.text2)
		}
	}
}
