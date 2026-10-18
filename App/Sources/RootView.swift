import EraseUI
import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
	case home
	case leaderboards
	case tiers
	case account
	case search
}

struct RootView: View {

	@Environment(AppModel.self) private var model

	var body: some View {
		@Bindable var model = model

		TabView(selection: $model.tab) {
			Tab("Home", systemImage: "house.fill", value: .home) {
				stack(.home) { HomeView() }
			}

			Tab("Leaderboards", systemImage: "trophy.fill", value: .leaderboards) {
				stack(.leaderboards) { LeaderboardsView() }
			}

			Tab("Tiers", systemImage: "chart.bar.fill", value: .tiers) {
				stack(.tiers) { TiersView() }
			}

			Tab("Account", systemImage: "person.crop.circle.fill", value: .account) {
				stack(.account) { ComingSoonView(title: "Account", systemImage: "person.crop.circle.fill") }
			}

			Tab(value: .search, role: .search) {
				stack(.search) { ComingSoonView(title: "Search", systemImage: "magnifyingglass") }
			}
		}
		.onOpenURL { url in
			if let route = Route(url: url) {
				model.open(route)
			}
		}
	}

	private func stack<Root: View>(_ tab: AppTab, @ViewBuilder root: () -> Root) -> some View {
		let path = Binding(
			get: { model.paths[tab] ?? [] },
			set: { model.paths[tab] = $0 }
		)

		return NavigationStack(path: path) {
			root().routes()
		}
	}
}

struct ComingSoonView: View {

	let title: LocalizedStringKey

	let systemImage: String

	var body: some View {
		ContentUnavailableView {
			Label(title, systemImage: systemImage)
		} description: {
			Text("Coming soon")
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Palette.background)
		.navigationTitle(title)
	}
}
