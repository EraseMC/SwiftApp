import EraseKit
import EraseUI
import SwiftUI

struct MatchView: View {

	let id: Int

	/// The player whose side is shown first, when the match was opened from their profile.
	let perspective: String?

	@Environment(AppModel.self) private var model

	@State private var phase: Phase<MatchDetail> = .loading

	var body: some View {
		ScrollView {
			LoadState(phase, retry: load) { match in
				VStack(alignment: .leading, spacing: Space.s4) {
					header(match)
					ForEach(ordered(match.players), id: \.name) { side in
						SideCard(side: side, ranked: match.ranked)
					}
				}
				.padding(Space.s4)
				.readableWidth()
			}
		}
		.background(Palette.background)
		.navigationTitle(Text(verbatim: "\(Copy.text("mt.title")) #\(id)"))
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				ShareLink(item: URL(string: "https://erasemc.com/matches/\(id)")!)
			}
		}
		.task { await load() }
	}

	private func header(_ match: MatchDetail) -> some View {
		let mode = Mode.of(match.mode)
		return HStack(spacing: Space.s3) {
			ModeIcon(mode, size: 40)
			VStack(alignment: .leading, spacing: 2) {
				Text(verbatim: mode.name).font(.eraseTitle3)
				HStack(spacing: Space.s2) {
					Text(match.ranked ? "Ranked" : "Casual")
						.foregroundStyle(match.ranked ? Palette.accentText : Palette.casual)
					Text(verbatim: "·")
					Text(match.endedAt, format: .dateTime.day().month().hour().minute())
					Text(verbatim: "·")
					Text(Duration.seconds(match.duration), format: .time(pattern: .minuteSecond))
				}
				.font(.eraseFootnote)
				.foregroundStyle(Palette.text2)
			}
		}
	}

	private func ordered(_ sides: [MatchSide]) -> [MatchSide] {
		guard let perspective else {
			return sides.sorted { $0.won && !$1.won }
		}
		return sides.sorted { first, _ in first.name.caseInsensitiveCompare(perspective) == .orderedSame }
	}

	private func load() async {
		if let fresh = await model.api.phase(API.match(id)) {
			withAnimation(Motion.popover) { phase = fresh }
		}
	}
}

private struct SideCard: View {

	let side: MatchSide

	let ranked: Bool

	@State private var expanded = false

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			NavigationLink(value: Route.player(side.name)) {
				HStack(spacing: Space.s3) {
					PlayerHead(side.name, size: 36)
					VStack(alignment: .leading, spacing: 2) {
						Text(verbatim: side.name)
							.font(.eraseHeadline)
							.foregroundStyle(Palette.text)
						Text(Copy.text(side.won ? "mt.winner" : "mt.loser").uppercased())
							.font(.eraseCaption.weight(.bold))
							.foregroundStyle(side.won ? Palette.win : Palette.loss)
					}
					Spacer()
					if ranked, let after = side.eloAfter {
						VStack(alignment: .trailing, spacing: 2) {
							Text(verbatim: "\(after)")
								.font(.eraseNumber.weight(.bold))
								.foregroundStyle(side.eloChange >= 0 ? Palette.win : Palette.loss)
							Text(verbatim: side.eloChange >= 0 ? "(+\(side.eloChange))" : "(\(side.eloChange))")
								.font(.eraseSmallNumber)
								.foregroundStyle(Palette.text3)
						}
					}
				}
			}
			.buttonStyle(.pressable)

			if let health = side.health {
				Hearts(halfHearts: Int(health.rounded()))
			}

			if let inventory = side.inventory, !inventory.isEmpty {
				InventoryGrid(items: inventory)
			}

			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: 3), spacing: Space.s2) {
				stat("mt.hits", "\(side.hits)")
				stat("mt.combo", "\(side.combo)")
				stat("mt.pots", "\(side.pots)")
				if expanded {
					stat("mt.kills", "\(side.kills)")
					stat("mt.criticals", "\(side.criticals)")
					stat("mt.damage", side.damage.formatted(.number.precision(.fractionLength(0...1))))
					stat("mt.accuracy", side.accuracy.formatted(.number.precision(.fractionLength(0))) + "%")
					stat("mt.stolen", "\(side.stolen)")
				}
			}

			Button {
				withAnimation(Motion.popover) { expanded.toggle() }
			} label: {
				Label(expanded ? "Less" : "More stats", systemImage: expanded ? "chevron.up" : "chevron.down")
					.font(.eraseFootnote.weight(.semibold))
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.pressable)
			.foregroundStyle(Palette.text2)
		}
		.panel()
	}

	private func stat(_ key: String, _ value: String) -> some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(Copy.text(key))
				.lineLimit(1)
				.minimumScaleFactor(0.8)
				.font(.eraseCaption)
				.foregroundStyle(Palette.text3)
			Text(verbatim: value)
				.font(.eraseNumber.weight(.bold))
				.foregroundStyle(Palette.text)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(Space.s2)
		.background(Palette.sunken, in: .rect(cornerRadius: Radius.sm))
	}
}

/// Ten Minecraft hearts drawn from half-heart health, as in the game's HUD.
private struct Hearts: View {

	let halfHearts: Int

	var body: some View {
		HStack(spacing: 1) {
			ForEach(0..<10, id: \.self) { index in
				let filled = halfHearts - index * 2
				ZStack {
					Image("UI/heart_background").resizable().interpolation(.none)
					if filled >= 2 {
						Image("UI/heart").resizable().interpolation(.none)
					} else if filled == 1 {
						Image("UI/heart_half").resizable().interpolation(.none)
					}
				}
				.frame(width: 18, height: 18)
			}
		}
		.accessibilityElement()
		.accessibilityLabel(Text(verbatim: "\(Double(halfHearts) / 2) ♥"))
	}
}

/// The leftover inventory: hotbar (slots 0–8) on the bottom row, the rest above, like the game.
private struct InventoryGrid: View {

	let items: [InventoryItem]

	var body: some View {
		let bySlot = Dictionary(items.map { ($0.slot, $0) }, uniquingKeysWith: { first, _ in first })
		let rows = [Array(9..<18), Array(18..<27), Array(27..<36), Array(0..<9)]

		VStack(spacing: 3) {
			ForEach(rows.indices, id: \.self) { row in
				HStack(spacing: 3) {
					ForEach(rows[row], id: \.self) { slot in
						Slot(item: bySlot[slot])
					}
				}
				.padding(.top, row == 3 ? Space.s1 : 0)
			}
		}
	}

	private struct Slot: View {

		let item: InventoryItem?

		var body: some View {
			ZStack(alignment: .bottomTrailing) {
				RoundedRectangle(cornerRadius: 4)
					.fill(Palette.sunken)
					.overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.line))
				if let item {
					Group {
						if let asset = ItemTexture.asset(for: item.item) {
							Image(asset).resizable().interpolation(.none)
						} else {
							Image(systemName: "questionmark.square.dashed").resizable().foregroundStyle(Palette.text3)
						}
					}
					.padding(4)
					.overlay {
						if item.enchanted {
							RoundedRectangle(cornerRadius: 4).fill(Color.purple.opacity(0.18)).blendMode(.plusLighter)
						}
					}
					if item.count > 1 {
						Text(verbatim: "\(item.count)")
							.font(.system(size: 10, weight: .bold, design: .monospaced))
							.foregroundStyle(.white)
							.shadow(color: .black, radius: 0, x: 1, y: 1)
							.padding(2)
					}
				}
			}
			.aspectRatio(1, contentMode: .fit)
			.accessibilityLabel(item.map { Text(verbatim: "\(ItemTexture.name(for: $0.item)) ×\($0.count)") } ?? Text(verbatim: ""))
		}
	}
}
