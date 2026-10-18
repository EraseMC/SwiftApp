import EraseKit
import EraseUI
import SwiftUI

/// A player's match history, newest first, paged by the `endedAt` of the last row.
struct PlayerMatchesView: View {

	let name: String

	var mode: ModeKey?

	@Environment(AppModel.self) private var model

	@State private var queue: Queue?

	@State private var matches: [MatchEntry] = []

	@State private var phase: Phase<Void> = .loading

	@State private var exhausted = false

	@State private var loadingMore = false

	private let pageSize = 20

	var body: some View {
		List {
			Section {
				Picker("Queue", selection: $queue) {
					Text("All").tag(Queue?.none)
					Text("Ranked").tag(Queue?.some(.ranked))
					Text("Casual").tag(Queue?.some(.casual))
				}
				.pickerStyle(.segmented)
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets())
			}

			switch phase {
			case .loading:
				ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
			case .failed(let error):
				Text(verbatim: error.message).foregroundStyle(Palette.loss)
			case .loaded:
				if matches.isEmpty {
					ContentUnavailableView("No matches yet", systemImage: "flag.checkered")
						.listRowBackground(Color.clear)
				}
				ForEach(matches) { match in
					NavigationLink(value: Route.match(match.id, perspective: name)) {
						MatchRow(match: match)
					}
					.listRowBackground(Palette.surface)
					.onAppear {
						if match.id == matches.last?.id {
							Task { await loadMore() }
						}
					}
				}
				if loadingMore {
					ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
				}
			}
		}
		.scrollContentBackground(.hidden)
		.background(Palette.background)
		.navigationTitle(mode.map { Mode.of($0).name } ?? String(localized: "Matches"))
		.navigationBarTitleDisplayMode(.inline)
		.refreshable { await reload() }
		.task(id: queue) { await reload() }
	}

	private func reload() async {
		exhausted = false
		switch await model.api.phase(API.matches(name, mode: mode, queue: queue, limit: pageSize)) {
		case .loaded(let page):
			matches = page
			exhausted = page.count < pageSize
			phase = .loaded(())
		case .failed(let error):
			phase = .failed(error)
		case .loading, .none:
			break
		}
	}

	private func loadMore() async {
		guard !exhausted, !loadingMore, let last = matches.last else { return }
		loadingMore = true
		defer { loadingMore = false }

		if case .loaded(let page) = await model.api.phase(API.matches(name, mode: mode, queue: queue, before: last.endedAt, limit: pageSize)) {
			let known = Set(matches.map(\.id))
			matches += page.filter { !known.contains($0.id) }
			exhausted = page.count < pageSize
		}
	}
}

struct MatchRow: View {

	let match: MatchEntry

	var body: some View {
		let mode = Mode.of(match.mode)

		HStack(spacing: Space.s3) {
			ModeIcon(mode, size: 30)

			VStack(alignment: .leading, spacing: 2) {
				HStack(spacing: Space.s1) {
					Text(verbatim: mode.name)
						.font(.eraseCallout.weight(.semibold))
						.foregroundStyle(Palette.text)
					if match.ranked {
						Image(systemName: "star.fill")
							.font(.system(size: 9))
							.foregroundStyle(Palette.accentText)
					}
				}
				Text(verbatim: opponents)
					.font(.eraseFootnote)
					.foregroundStyle(Palette.text2)
					.lineLimit(1)
			}

			Spacer(minLength: Space.s2)

			VStack(alignment: .trailing, spacing: 2) {
				Text(match.won ? "Win" : "Loss")
					.font(.eraseFootnote.weight(.bold))
					.foregroundStyle(match.won ? Palette.win : Palette.loss)
				if match.ranked && match.eloChange != 0 {
					Text(verbatim: match.eloChange > 0 ? "+\(match.eloChange)" : "\(match.eloChange)")
						.font(.eraseSmallNumber)
						.foregroundStyle(match.eloChange > 0 ? Palette.win : Palette.loss)
				} else {
					Text(match.endedAt, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
						.font(.eraseCaption)
						.foregroundStyle(Palette.text3)
				}
			}
		}
		.padding(.vertical, Space.s1)
		.accessibilityElement(children: .combine)
	}

	private var opponents: String {
		let names = match.opponents.map(\.name)
		return names.isEmpty ? "—" : "vs " + names.joined(separator: ", ")
	}
}
