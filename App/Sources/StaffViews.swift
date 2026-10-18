import EraseKit
import EraseUI
import LocalAuthentication
import SwiftUI

/// Staff panel home: the numbers for the member's role and the sections it opens.
struct StaffHomeView: View {

	@Environment(AppModel.self) private var model

	@State private var phase: Phase<StaffOverview> = .loading

	var body: some View {
		ScrollView {
			LoadState(phase, retry: load) { overview in
				VStack(alignment: .leading, spacing: Space.s4) {
					VStack(alignment: .leading, spacing: Space.s1) {
						Text(Copy.text("staff.overview.title", ["name": overview.me.name])).font(.eraseTitle2)
						Text(Copy.text("staff.role.\(overview.me.role.rawValue)"))
							.font(.eraseFootnote.weight(.semibold))
							.foregroundStyle(overview.me.rank.tint)
					}

					LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
						tile("staff.overview.online", overview.online)
						tile("staff.overview.queue", overview.queue.values.reduce(0, +))
						if overview.me.role >= .admin { tile("staff.overview.pending", overview.pendingReviews) }
						tile("staff.overview.myWeek", overview.myTestsWeek)
						if overview.me.role >= .moderator {
							tile("staff.overview.bans", overview.activeBans)
							tile("staff.overview.mutes", overview.activeMutes)
						}
					}

					VStack(spacing: 0) {
						ForEach(overview.me.sections.filter { $0 != "overview" }, id: \.self) { section in
							if let route = Route(staffSection: section) {
								NavigationLink(value: route) {
									HStack {
										Label(Copy.text("staff.section.\(section)"), systemImage: icon(section))
											.font(.eraseHeadline)
											.foregroundStyle(Palette.text)
										Spacer()
										Image(systemName: "chevron.right").foregroundStyle(Palette.text3)
									}
									.padding(Space.s4)
									.contentShape(.rect)
								}
								.buttonStyle(.pressable)
							}
						}
					}
					.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
					.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))

					SectionHeader(LocalizedStringKey(Copy.text("staff.overview.recent")))
					if overview.recent.isEmpty {
						Text(Copy.text("staff.overview.recentEmpty")).font(.eraseFootnote).foregroundStyle(Palette.text3)
					}
					ForEach(Array(overview.recent.enumerated()), id: \.offset) { _, row in
						LogRow(row: row)
					}
				}
				.padding(Space.s4)
			}
		}
		.background(Palette.background)
		.navigationTitle(Copy.text("staff.title"))
		.refreshable { await load() }
		.task { await load() }
	}

	private func tile(_ key: String, _ value: Int?) -> some View {
		StatTile(LocalizedStringKey(Copy.text(key)), value: value.map(String.init) ?? "—")
	}

	private func icon(_ section: String) -> String {
		switch section {
		case "tiers": "chart.bar.fill"
		case "players": "person.2.fill"
		case "reviews": "checkmark.seal.fill"
		case "testers": "person.badge.shield.checkmark.fill"
		case "team": "person.3.fill"
		default: "square.grid.2x2"
		}
	}

	private func load() async {
		if let fresh = await model.api.phase(API.Staff.overview) {
			withAnimation(Motion.popover) { phase = fresh }
		}
	}
}

extension Route {
	init?(staffSection: String) {
		switch staffSection {
		case "tiers": self = .staffTiers
		case "players": self = .staffPlayers
		case "reviews": self = .staffReviews
		case "testers": self = .staffTesters
		case "team": self = .staffTeam
		default: return nil
		}
	}
}

struct LogRow: View {

	let row: StaffLogRow

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack {
				Text(Copy.text("staff.log.\(row.action)") == "staff.log.\(row.action)" ? row.action : Copy.text("staff.log.\(row.action)"))
					.font(.eraseFootnote.weight(.bold))
				Text(verbatim: row.target).font(.eraseFootnote)
				Spacer()
				Text(row.at, format: .relative(presentation: .named))
					.font(.eraseCaption)
					.foregroundStyle(Palette.text3)
			}
			if !row.details.isEmpty {
				Text(verbatim: row.details).font(.eraseCaption).foregroundStyle(Palette.text2).lineLimit(2)
			}
			Text(Copy.text("staff.player.by", ["name": row.staff])).font(.eraseCaption).foregroundStyle(Palette.text3)
		}
		.panel(padding: Space.s3)
	}
}

// MARK: - Players

struct StaffPlayersView: View {

	@Environment(AppModel.self) private var model

	@State private var query = ""

	@State private var rows: [StaffPlayerRow] = []

	var body: some View {
		List {
			if query.isEmpty {
				Text(Copy.text("staff.players.hint")).foregroundStyle(Palette.text3)
			} else if rows.isEmpty {
				Text(Copy.text("staff.players.empty")).foregroundStyle(Palette.text3)
			}
			ForEach(rows, id: \.name) { row in
				NavigationLink(value: Route.staffPlayer(row.name)) {
					HStack(spacing: Space.s3) {
						PlayerHead(row.name, size: 30)
						RankedName(row.name, rank: row.rank).font(.eraseHeadline)
						Spacer()
						Text(row.lastSeen, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
							.font(.eraseCaption)
							.foregroundStyle(Palette.text3)
					}
				}
			}
		}
		.font(.eraseCallout)
		.navigationTitle(Copy.text("staff.players.title"))
		.searchable(text: $query, prompt: Text(Copy.text("staff.players.search")))
		.textInputAutocapitalization(.never)
		.autocorrectionDisabled()
		.task(id: query) {
			guard !query.isEmpty else { rows = []; return }
			try? await Task.sleep(for: .milliseconds(250))
			if case .loaded(let found) = await model.api.phase(API.Staff.players(query)) {
				rows = found
			}
		}
	}
}

struct StaffPlayerView: View {

	let name: String

	@Environment(AppModel.self) private var model

	@Environment(AuthModel.self) private var auth

	@State private var phase: Phase<StaffPlayerCard> = .loading

	@State private var punishing: String?

	@State private var pardoning: String?

	@State private var changingRank = false

	@State private var placing = false

	@State private var result: String?

	var body: some View {
		ScrollView {
			LoadState(phase, retry: load) { card in
				VStack(alignment: .leading, spacing: Space.s4) {
					header(card)
					actions(card)
					punishments(card)
					tiers(card)
					alts(card)
					history(card)
				}
				.padding(Space.s4)
			}
		}
		.background(Palette.background)
		.navigationTitle(name)
		.navigationBarTitleDisplayMode(.inline)
		.refreshable { await load() }
		.task { await load() }
		.sheet(item: Binding(get: { punishing.map(Wrapped.init) }, set: { punishing = $0?.value })) { type in
			PunishSheet(name: name, type: type.value) { await perform($0) }
		}
		.sheet(isPresented: $changingRank) {
			RankSheet(name: name) { await perform($0) }
		}
		.sheet(isPresented: $placing) {
			PlacementSheet(name: name) { await perform($0) }
		}
		.confirmationDialog(
			Copy.text(pardoning == "ban" ? "staff.action.unbanConfirm" : "staff.action.unmuteConfirm", ["name": name]),
			isPresented: Binding(get: { pardoning != nil }, set: { if !$0 { pardoning = nil } }),
			titleVisibility: .visible
		) {
			Button(Copy.text("staff.action.confirm")) {
				if let type = pardoning {
					Task { await perform(API.Staff.pardon(name, type: type)) }
				}
			}
		}
		.alert(Text(verbatim: result ?? ""), isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } })) {
			Button("OK") {}
		}
	}

	private func header(_ card: StaffPlayerCard) -> some View {
		HStack(spacing: Space.s3) {
			PlayerHead(card.name, size: 56)
			VStack(alignment: .leading, spacing: 2) {
				RankedName(card.name, rank: card.rank).font(.eraseTitle2)
				Text(Copy.text(card.online == true ? "staff.player.online" : "staff.player.offline"))
					.font(.eraseFootnote)
					.foregroundStyle(card.online == true ? Palette.win : Palette.text3)
				Text(verbatim: [
					card.device,
					Copy.text("staff.player.hours", ["count": card.playTime / 3600]),
				].compactMap { $0 }.joined(separator: " · "))
					.font(.eraseCaption)
					.foregroundStyle(Palette.text3)
			}
			Spacer()
			NavigationLink(value: Route.player(card.name)) {
				Image(systemName: "person.crop.circle")
			}
		}
	}

	@ViewBuilder
	private func actions(_ card: StaffPlayerCard) -> some View {
		if card.canPunish {
			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: 3), spacing: Space.s2) {
				action("staff.action.ban", "hammer.fill", Palette.loss) { punishing = "ban" }
				action("staff.action.mute", "speaker.slash.fill", Palette.warn) { punishing = "mute" }
				action("staff.action.kick", "figure.walk.departure", Palette.text2) { punishing = "kick" }
				action("staff.action.unban", "lock.open.fill", Palette.win) { pardoning = "ban" }
				action("staff.action.unmute", "speaker.wave.2.fill", Palette.win) { pardoning = "mute" }
				if card.canRank {
					action("staff.action.rank", "crown.fill", Palette.gold) { changingRank = true }
				}
			}
		} else {
			Text(Copy.text("staff.player.protected")).font(.eraseFootnote).foregroundStyle(Palette.text3)
		}
	}

	private func action(_ key: String, _ icon: String, _ tint: Color, run: @escaping () -> Void) -> some View {
		Button(action: run) {
			VStack(spacing: Space.s1) {
				Image(systemName: icon).font(.title3)
				Text(Copy.text(key)).font(.eraseCaption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
			}
			.foregroundStyle(tint)
			.frame(maxWidth: .infinity)
			.padding(.vertical, Space.s3)
			.background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
			.overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(Palette.line))
		}
		.buttonStyle(.pressable)
	}

	private func punishments(_ card: StaffPlayerCard) -> some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			SectionHeader(LocalizedStringKey(Copy.text("staff.player.punishments")))
			if card.punishments.isEmpty {
				Text(Copy.text("staff.player.punishmentsEmpty")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			}
			ForEach(card.punishments) { row in
				VStack(alignment: .leading, spacing: 2) {
					HStack {
						Text(Copy.text("staff.log.\(row.type)")).font(.eraseFootnote.weight(.bold))
							.foregroundStyle(row.active ? Palette.loss : Palette.text2)
						Text(Copy.text(row.active ? "staff.player.active" : "staff.player.ended"))
							.font(.eraseCaption)
							.foregroundStyle(Palette.text3)
						Spacer()
						Text(row.createdAt, format: .dateTime.day().month().year()).font(.eraseCaption).foregroundStyle(Palette.text3)
					}
					Text(verbatim: row.reason).font(.eraseCallout)
					Text(verbatim: "\(Copy.text("staff.player.by", ["name": row.executor])) · \(expiry(row))")
						.font(.eraseCaption)
						.foregroundStyle(Palette.text3)
				}
				.panel(padding: Space.s3)
			}
		}
	}

	private func expiry(_ row: PunishmentRow) -> String {
		if row.expiresAt.timeIntervalSince1970 <= 0 {
			return Copy.text("staff.player.forever")
		}
		return Copy.text("staff.player.until", ["date": row.expiresAt.formatted(date: .abbreviated, time: .shortened)])
	}

	private func tiers(_ card: StaffPlayerCard) -> some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			SectionHeader(LocalizedStringKey(Copy.text("staff.player.tiers"))) {
				if auth.staffRole == "owner" {
					Button(Copy.text("staff.place.submit")) { placing = true }
						.font(.eraseFootnote.weight(.semibold))
				}
			}
			if card.tiers.isEmpty {
				Text(Copy.text("staff.player.tiersEmpty")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			}
			ForEach(card.tiers) { placement in
				HStack {
					ModeIcon(Mode.of(placement.board), size: 22)
					Text(verbatim: "\(Mode.of(placement.board).name) · \(placement.platform.rawValue.uppercased())")
						.font(.eraseCallout)
					Spacer()
					TierChip(label: placement.label, level: placement.level, inactive: placement.inactive)
				}
				.panel(padding: Space.s3)
				.contextMenu {
					if auth.staffRole == "owner" {
						Button(role: .destructive) {
							Task { await perform(API.Staff.removePlacement(placement.id)) }
						} label: {
							Label("Remove tier", systemImage: "trash")
						}
					}
				}
			}
		}
	}

	private func alts(_ card: StaffPlayerCard) -> some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			SectionHeader(LocalizedStringKey(Copy.text("staff.player.alts")))
			if card.alts.isEmpty {
				Text(Copy.text("staff.player.altsEmpty")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			}
			ForEach(card.alts, id: \.name) { alt in
				NavigationLink(value: Route.staffPlayer(alt.name)) {
					HStack {
						RankedName(alt.name, rank: alt.rank).font(.eraseHeadline)
						if alt.banned {
							Text(Copy.text("staff.player.banned")).font(.eraseCaption).foregroundStyle(Palette.loss)
						}
						Spacer()
						Text(Copy.text(alt.via == "device" ? "staff.player.viaDevice" : "staff.player.viaNetwork"))
							.font(.eraseCaption)
							.foregroundStyle(Palette.text3)
					}
					.panel(padding: Space.s3)
				}
				.buttonStyle(.pressable)
			}
		}
	}

	private func history(_ card: StaffPlayerCard) -> some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			SectionHeader(LocalizedStringKey(Copy.text("staff.player.history")))
			if card.history.isEmpty {
				Text(Copy.text("staff.player.historyEmpty")).font(.eraseFootnote).foregroundStyle(Palette.text3)
			}
			ForEach(Array(card.history.enumerated()), id: \.offset) { _, row in
				LogRow(row: row)
			}
		}
	}

	private func perform(_ endpoint: Endpoint<StaffActionResult>) async {
		guard await StaffGuard.confirm() else { return }
		switch await model.api.phase(endpoint) {
		case .loaded(let answer):
			result = answer.sent
				? [Copy.text("staff.action.done"), answer.output.isEmpty ? nil : Copy.text("staff.action.server", ["output": answer.output])]
					.compactMap { $0 }.joined(separator: "\n")
				: Copy.text("staff.action.offline")
			await load()
		case .failed(let error):
			result = Copy.text("staff.action.failed", ["message": error.message])
		case .loading, .none:
			break
		}
	}

	private func load() async {
		if let fresh = await model.api.phase(API.Staff.player(name)) {
			withAnimation(Motion.popover) { phase = fresh }
		}
	}
}

private struct Wrapped: Identifiable {
	let value: String
	var id: String { value }
}

/// Every action that changes a player runs only after the device owner confirms it.
enum StaffGuard {
	@MainActor
	static func confirm() async -> Bool {
		let context = LAContext()
		var error: NSError?
		guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
			return true
		}
		return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: Copy.text("staff.action.confirm"))) ?? false
	}
}

private struct PunishSheet: View {

	let name: String

	let type: String

	let submit: (Endpoint<StaffActionResult>) async -> Void

	@Environment(\.dismiss) private var dismiss

	@State private var reason = ""

	@State private var duration = "1d"

	private static let durations = ["30m", "1h", "1d", "7d", "30d", "perm"]

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField(Copy.text("staff.action.reason"), text: $reason, axis: .vertical)
						.lineLimit(2...4)
				} footer: {
					Text(Copy.text("staff.action.reasonHint"))
				}
				if type != "kick" {
					Section(Copy.text("staff.action.duration")) {
						Picker(Copy.text("staff.action.duration"), selection: $duration) {
							ForEach(Self.durations, id: \.self) { option in
								Text(Copy.text("staff.action.d\(option)")).tag(option)
							}
						}
						.pickerStyle(.inline)
						.labelsHidden()
					}
				}
			}
			.navigationTitle(Copy.text("staff.action.title.\(type)", ["name": name]))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(Copy.text("staff.action.cancel")) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(Copy.text("staff.action.confirm")) {
						let endpoint = API.Staff.punish(name, type: type, duration: duration, reason: reason.trimmingCharacters(in: .whitespacesAndNewlines))
						dismiss()
						Task { await submit(endpoint) }
					}
					.disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reason.count > 120)
				}
			}
		}
	}
}

private struct RankSheet: View {

	let name: String

	let submit: (Endpoint<StaffActionResult>) async -> Void

	@Environment(AppModel.self) private var model

	@Environment(\.dismiss) private var dismiss

	@State private var ranks: [PlayerRank] = []

	var body: some View {
		NavigationStack {
			List(ranks.sorted { $0.priority > $1.priority }, id: \.name) { rank in
				Button {
					dismiss()
					Task { await submit(API.Staff.setRank(name, rank: rank.name)) }
				} label: {
					Text(verbatim: rank.displayName).foregroundStyle(rank.tint)
				}
			}
			.navigationTitle(Copy.text("staff.rank.title", ["name": name]))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(Copy.text("staff.action.cancel")) { dismiss() }
				}
			}
			.safeAreaInset(edge: .bottom) {
				Text(Copy.text("staff.rank.hint")).font(.eraseFootnote).foregroundStyle(Palette.text3).padding()
			}
			.task {
				if case .loaded(let all) = await model.api.phase(API.Staff.ranks) { ranks = all }
			}
		}
	}
}

private struct PlacementSheet: View {

	let name: String

	let submit: (Endpoint<StaffActionResult>) async -> Void

	@Environment(\.dismiss) private var dismiss

	@State private var board: ModeKey = .noDebuff

	@State private var platform: TierPlatform = .pc

	@State private var tier = "LT5"

	private static let tiers = ["HT1", "LT1", "HT2", "LT2", "HT3", "LT3", "HT4", "LT4", "HT5", "LT5"]

	var body: some View {
		NavigationStack {
			Form {
				Picker(Copy.text("staff.place.mode"), selection: $board) {
					ForEach(Mode.tiers) { Text(verbatim: $0.name).tag($0.key) }
				}
				Picker(Copy.text("staff.place.league"), selection: $platform) {
					ForEach(TierPlatform.allCases, id: \.self) { Text(verbatim: $0.rawValue.uppercased()).tag($0) }
				}
				.pickerStyle(.segmented)
				Picker(Copy.text("staff.place.tier"), selection: $tier) {
					ForEach(Self.tiers, id: \.self) { Text(verbatim: $0).tag($0) }
				}
			}
			.navigationTitle(Copy.text("staff.place.title"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(Copy.text("staff.action.cancel")) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(Copy.text("staff.place.submit")) {
						let endpoint = API.Staff.place(name, board: board, platform: platform, tier: tier)
						dismiss()
						Task { await submit(endpoint) }
					}
				}
			}
		}
	}
}

// MARK: - Tiers, reviews, testers, team

struct StaffTiersView: View {

	@Environment(AppModel.self) private var model

	@Environment(AuthModel.self) private var auth

	@State private var queue: [TierQueueEntry] = []

	@State private var tests: [TierTest] = []

	@State private var mine = true

	var body: some View {
		List {
			Section(Copy.text("staff.tiers.queue")) {
				if queue.isEmpty {
					Text(Copy.text("staff.tiers.queueEmpty")).foregroundStyle(Palette.text3)
				}
				ForEach(queue, id: \.position) { entry in
					HStack(spacing: Space.s3) {
						Text(verbatim: "\(entry.position)").font(.eraseNumber).foregroundStyle(Palette.text3)
						PlayerHead(entry.name, size: 26)
						RankedName(entry.name, rank: entry.rank).font(.eraseHeadline)
						Spacer()
						ModeIcon(Mode.of(entry.board), size: 18)
						Text(verbatim: entry.platform.rawValue.uppercased()).font(.eraseCaption)
					}
				}
			}

			Section {
				if ["admin", "owner"].contains(auth.staffRole ?? "") {
					Picker("", selection: $mine) {
						Text(Copy.text("staff.tiers.mine")).tag(true)
						Text(Copy.text("staff.tiers.all")).tag(false)
					}
					.pickerStyle(.segmented)
				}
				if tests.isEmpty {
					Text(Copy.text("staff.tiers.testsEmpty")).foregroundStyle(Palette.text3)
				}
				ForEach(tests) { TestRow(test: $0) }
			} header: {
				Text(Copy.text("staff.tiers.tests"))
			}
		}
		.font(.eraseCallout)
		.navigationTitle(Copy.text("staff.tiers.title"))
		.refreshable { await load() }
		.task(id: mine) { await load() }
	}

	private func load() async {
		let api = model.api
		async let queuePhase = api.phase(API.Staff.tierQueue)
		async let testsPhase = api.phase(API.Staff.tests(mine: mine))
		if case .loaded(let value) = await queuePhase { queue = value }
		if case .loaded(let value) = await testsPhase { tests = value }
	}
}

struct TestRow: View {

	let test: TierTest

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s1) {
			HStack {
				Text(verbatim: test.name).font(.eraseHeadline)
				Spacer()
				TierChip(label: "\(test.band.rawValue)\(test.level)", level: test.level)
			}
			Text(verbatim: "\(Mode.of(test.board).name) · \(test.platform.rawValue.uppercased()) · \(test.playerScore)–\(test.testerScore) · \(test.tester)")
				.font(.eraseCaption)
				.foregroundStyle(Palette.text3)
			HStack {
				Text(Copy.text("staff.status.\(test.status.rawValue)"))
					.font(.eraseCaption.weight(.semibold))
					.foregroundStyle(test.status == .applied ? Palette.win : test.status == .pending ? Palette.warn : Palette.loss)
				Spacer()
				Text(test.createdAt, format: .dateTime.day().month())
					.font(.eraseCaption)
					.foregroundStyle(Palette.text3)
			}
		}
	}
}

struct StaffReviewsView: View {

	@Environment(AppModel.self) private var model

	@State private var reviews: [TierTest] = []

	@State private var result: String?

	var body: some View {
		List {
			if reviews.isEmpty {
				Text(Copy.text("staff.reviews.empty")).foregroundStyle(Palette.text3)
			}
			ForEach(reviews) { test in
				VStack(alignment: .leading, spacing: Space.s2) {
					TestRow(test: test)
					HStack {
						Button(Copy.text("staff.reviews.approve")) { Task { await review(test, approve: true) } }
							.buttonStyle(.borderedProminent)
							.tint(Palette.win)
						Button(Copy.text("staff.reviews.reject"), role: .destructive) { Task { await review(test, approve: false) } }
							.buttonStyle(.bordered)
					}
				}
			}
		}
		.font(.eraseCallout)
		.navigationTitle(Copy.text("staff.reviews.title"))
		.refreshable { await load() }
		.task { await load() }
		.alert(Text(verbatim: result ?? ""), isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } })) {
			Button("OK") {}
		}
	}

	private func review(_ test: TierTest, approve: Bool) async {
		guard await StaffGuard.confirm() else { return }
		switch await model.api.phase(API.Staff.review(test.id, approve: approve)) {
		case .loaded:
			result = approve
				? Copy.text("staff.reviews.approved", ["name": test.name, "tier": "\(test.band.rawValue)\(test.level)"])
				: Copy.text("staff.reviews.rejected", ["name": test.name])
			await load()
		case .failed(let error):
			result = Copy.text("staff.action.failed", ["message": error.message])
		default:
			break
		}
	}

	private func load() async {
		if case .loaded(let value) = await model.api.phase(API.Staff.reviews) { reviews = value }
	}
}

struct StaffTestersView: View {

	@Environment(AppModel.self) private var model

	@State private var testers: [TesterStats] = []

	var body: some View {
		List {
			if testers.isEmpty {
				Text(Copy.text("staff.testers.empty")).foregroundStyle(Palette.text3)
			}
			ForEach(testers, id: \.name) { tester in
				VStack(alignment: .leading, spacing: Space.s1) {
					HStack {
						RankedName(tester.name, rank: tester.rank).font(.eraseHeadline)
						Spacer()
						Text(verbatim: "\(tester.tests)").font(.eraseNumber.weight(.bold))
					}
					Text(verbatim: "\(Copy.text("staff.col.month")): \(tester.recent) · \(Copy.text("staff.col.pending")): \(tester.pending) · \(Copy.text("staff.col.rejected")): \(tester.rejected)")
						.font(.eraseCaption)
						.foregroundStyle(Palette.text3)
				}
			}
		}
		.font(.eraseCallout)
		.navigationTitle(Copy.text("staff.testers.title"))
		.refreshable { await load() }
		.task { await load() }
	}

	private func load() async {
		if case .loaded(let value) = await model.api.phase(API.Staff.testers) { testers = value }
	}
}

struct StaffTeamView: View {

	@Environment(AppModel.self) private var model

	@State private var team: [TeamMember] = []

	var body: some View {
		List {
			if team.isEmpty {
				Text(Copy.text("staff.team.empty")).foregroundStyle(Palette.text3)
			}
			ForEach(team, id: \.name) { member in
				NavigationLink(value: Route.staffPlayer(member.name)) {
					HStack(spacing: Space.s3) {
						PlayerHead(member.name, size: 30)
						VStack(alignment: .leading, spacing: 2) {
							RankedName(member.name, rank: member.rank).font(.eraseHeadline)
							Text(verbatim: "\(Copy.text("staff.col.bans")) \(member.bans) · \(Copy.text("staff.col.mutes")) \(member.mutes) · \(Copy.text("staff.col.tests")) \(member.tests)")
								.font(.eraseCaption)
								.foregroundStyle(Palette.text3)
						}
						Spacer()
						Circle().fill(member.online == true ? Palette.win : Palette.text3).frame(width: 8, height: 8)
					}
				}
			}
		}
		.font(.eraseCallout)
		.navigationTitle(Copy.text("staff.team.title"))
		.refreshable { await load() }
		.task { await load() }
	}

	private func load() async {
		if case .loaded(let value) = await model.api.phase(API.Staff.team) { team = value }
	}
}
