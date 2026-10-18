import EraseKit
import EraseUI
import SwiftUI

@main
struct EraseApp: App {

	@State private var model = AppModel()

	@State private var auth = AuthModel(api: .production)

	@AppStorage("theme") private var theme: AppTheme = .system

	init() {
		Appearance.apply()
	}

	var body: some Scene {
		WindowGroup {
			RootView()
				.environment(model)
				.environment(auth)
				.tint(Palette.accentText)
				.preferredColorScheme(theme.colorScheme)
		}
	}
}

/// App-wide state shared by every tab.
@MainActor
@Observable
final class AppModel {

	let api: APIClient

	var tab: AppTab

	/// Each tab keeps its own navigation history.
	var paths: [AppTab: [Route]] = [:]

	init(api: APIClient = .production) {
		self.api = api
		// CI screenshots launch the app with `-screen <tab>` to open a given tab.
		self.tab = UserDefaults.standard.string(forKey: "screen").flatMap(AppTab.init(rawValue:)) ?? .home
		// …and `-route erasemc://player/<name>` to open a pushed screen without the system's open-link prompt.
		if let link = UserDefaults.standard.string(forKey: "route"), let url = URL(string: link), let route = Route(url: url) {
			paths[tab] = [route]
		}
	}

	/// Shows a deep-linked screen on top of the current tab.
	func open(_ route: Route) {
		paths[tab, default: []].append(route)
	}
}
