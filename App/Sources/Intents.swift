import AppIntents
import EraseKit
import Foundation

/// "How many are online on Erase?" — answered by Siri without opening the app.
struct ServerOnlineIntent: AppIntent {
	static let title: LocalizedStringResource = "Players online"
	static let description = IntentDescription("Tells how many players are on Erase right now.")

	func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
		let status = try await APIClient.production.send(API.networkStatus)
		guard let online = status.online else {
			return .result(value: 0, dialog: "The Erase server is not answering right now.")
		}
		return .result(value: online, dialog: "\(online) players are on Erase right now.")
	}
}

/// Opens a player's profile in the app.
struct OpenPlayerIntent: AppIntent {
	static let title: LocalizedStringResource = "Open player"
	static let description = IntentDescription("Opens a player's Erase profile.")

	@Parameter(title: "Player name")
	var name: String

	func perform() async throws -> some IntentResult & OpensIntent {
		let path = name.trimmingCharacters(in: .whitespaces).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
		return .result(opensIntent: OpenURLIntent(URL(string: "erasemc://player/\(path)")!))
	}
}

struct EraseShortcuts: AppShortcutsProvider {
	static var appShortcuts: [AppShortcut] {
		AppShortcut(
			intent: ServerOnlineIntent(),
			phrases: [
				"How many players are on \(.applicationName)",
				"Who is online on \(.applicationName)",
			],
			shortTitle: "Players online",
			systemImageName: "person.2.fill"
		)
		AppShortcut(
			intent: OpenPlayerIntent(),
			phrases: ["Open a player in \(.applicationName)"],
			shortTitle: "Open player",
			systemImageName: "person.crop.circle"
		)
	}
}
