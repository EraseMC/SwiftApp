import EraseKit
import EraseUI
import SwiftUI

@main
struct EraseApp: App {

	@State private var model = AppModel()

	var body: some Scene {
		WindowGroup {
			RootView()
				.environment(model)
				.tint(Palette.accent)
		}
	}
}

/// App-wide state shared by every tab.
@MainActor
@Observable
final class AppModel {

	let api: APIClient

	var tab: AppTab

	init(api: APIClient = .production) {
		self.api = api
		// CI screenshots launch the app with `-screen <tab>` to open a given tab.
		self.tab = UserDefaults.standard.string(forKey: "screen").flatMap(AppTab.init(rawValue:)) ?? .home
	}
}
