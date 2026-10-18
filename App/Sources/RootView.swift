import EraseUI
import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
	case home
	case leaderboards
	case tiers
	case clubs
	case account
	case search
}

struct RootView: View {

	@Environment(AppModel.self) private var model

	var body: some View {
		@Bindable var model = model

		TabView(selection: $model.tab) {
			Tab("Home", systemImage: "house.fill", value: .home) {
				NavigationStack { HomeView() }
			}

			Tab("Leaderboards", systemImage: "trophy.fill", value: .leaderboards) {
				NavigationStack { ComingSoonView(title: "Leaderboards", systemImage: "trophy.fill") }
			}

			Tab("Tiers", systemImage: "chart.bar.fill", value: .tiers) {
				NavigationStack { ComingSoonView(title: "Tiers", systemImage: "chart.bar.fill") }
			}

			Tab("Clubs", systemImage: "shield.lefthalf.filled", value: .clubs) {
				NavigationStack { ComingSoonView(title: "Clubs", systemImage: "shield.lefthalf.filled") }
			}

			Tab("Account", systemImage: "person.crop.circle.fill", value: .account) {
				NavigationStack { ComingSoonView(title: "Account", systemImage: "person.crop.circle.fill") }
			}

			Tab(value: .search, role: .search) {
				NavigationStack { ComingSoonView(title: "Search", systemImage: "magnifyingglass") }
			}
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
