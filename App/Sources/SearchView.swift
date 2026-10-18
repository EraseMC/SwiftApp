import EraseKit
import EraseUI
import SwiftUI

struct SearchView: View {

	@Environment(AppModel.self) private var model

	@State private var query = ""

	@State private var results: [PlayerCard] = []

	@State private var searching = false

	/// Most recent first, kept small. Stored as one newline-joined string.
	@AppStorage("search.recent") private var recentStorage = ""

	var body: some View {
		List {
			if query.trimmingCharacters(in: .whitespaces).isEmpty {
				if !recent.isEmpty {
					Section {
						ForEach(recent, id: \.self) { name in
							NavigationLink(value: Route.player(name)) {
								HStack(spacing: Space.s3) {
									PlayerHead(name, size: 28)
									Text(verbatim: name).font(.eraseCallout)
								}
							}
						}
						.onDelete { offsets in
							var names = recent
							names.remove(atOffsets: offsets)
							recentStorage = names.joined(separator: "\n")
						}
					} header: {
						Text("Recent")
					}
				}
			} else {
				ForEach(results, id: \.name) { card in
					NavigationLink(value: Route.player(card.name)) {
						HStack(spacing: Space.s3) {
							PlayerHead(card.name, size: 32)
							VStack(alignment: .leading, spacing: 2) {
								RankedName(card.name, rank: card.rank).font(.eraseHeadline)
								Text(verbatim: card.rank.displayName)
									.font(.eraseCaption)
									.foregroundStyle(Palette.text3)
							}
							Spacer()
							if card.peakElo > 0 {
								Text(verbatim: "\(card.peakElo)")
									.font(.eraseNumber)
									.foregroundStyle(Palette.accentText)
							}
						}
					}
					.simultaneousGesture(TapGesture().onEnded { remember(card.name) })
				}
			}
		}
		.scrollContentBackground(.hidden)
		.background(Palette.background)
		.overlay {
			if !query.isEmpty, results.isEmpty, !searching {
				ContentUnavailableView.search(text: query)
			}
		}
		.navigationTitle("Search")
		.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Player name"))
		.textInputAutocapitalization(.never)
		.autocorrectionDisabled()
		.task(id: query) { await search() }
	}

	private var recent: [String] {
		recentStorage.split(separator: "\n").map(String.init)
	}

	private func remember(_ name: String) {
		let names = [name] + recent.filter { $0.caseInsensitiveCompare(name) != .orderedSame }
		recentStorage = names.prefix(10).joined(separator: "\n")
	}

	private func search() async {
		let text = query.trimmingCharacters(in: .whitespaces)
		guard !text.isEmpty else {
			results = []
			return
		}

		// Debounce: a newer keystroke cancels this task before the request goes out.
		try? await Task.sleep(for: .milliseconds(250))
		guard !Task.isCancelled else { return }

		searching = true
		defer { searching = false }

		if case .loaded(let cards) = await model.api.phase(API.searchPlayers(text, limit: 20)) {
			// The same name can exist twice after an Xbox account change; show it once.
			var seen = Set<String>()
			results = cards.filter { seen.insert($0.name.lowercased()).inserted }
		}
	}
}
