import EraseKit
import EraseUI
import SwiftUI

/// Every screen a tab can push. Deep links (`erasemc://player/<name>`) resolve to these too.
enum Route: Hashable {
	case player(String)
	case playerMatches(String)
	case ladder(player: String, mode: ModeKey)
	case match(Int, perspective: String?)
	case club(String)

	init?(url: URL) {
		guard url.scheme == "erasemc" || url.host() == "erasemc.com" else {
			return nil
		}

		// erasemc://player/Name and https://erasemc.com/profile/Name both land on the profile.
		var parts = url.pathComponents.filter { $0 != "/" }
		if url.scheme == "erasemc", let host = url.host() {
			parts.insert(host, at: 0)
		}

		guard parts.count >= 2 else {
			return nil
		}

		switch parts[0] {
		case "player", "profile":
			self = .player(parts[1])
		case "matches", "match":
			guard let id = Int(parts[1]) else { return nil }
			self = .match(id, perspective: nil)
		case "clubs", "club":
			self = .club(parts[1])
		default:
			return nil
		}
	}
}

extension View {

	/// Registers the destination for every `Route`, once per navigation stack.
	func routes() -> some View {
		navigationDestination(for: Route.self) { route in
			switch route {
			case .player(let name):
				PlayerView(name: name)
			case .playerMatches(let name):
				ComingSoonView(title: "Matches", systemImage: "list.bullet").id(name)
			case .ladder(let player, let mode):
				ComingSoonView(title: "Duels", systemImage: "chart.xyaxis.line").id("\(player)-\(mode.rawValue)")
			case .match(let id, _):
				ComingSoonView(title: "Match", systemImage: "flag.checkered").id(id)
			case .club(let name):
				ComingSoonView(title: "Clubs", systemImage: "shield.lefthalf.filled").id(name)
			}
		}
	}
}

extension APIClient {

	/// One request turned into a screen state.
	func phase<Value: Decodable & Sendable>(_ endpoint: Endpoint<Value>) async -> Phase<Value>? {
		do throws(APIError) {
			return .loaded(try await send(endpoint))
		} catch .cancelled {
			return nil
		} catch {
			return .failed(error)
		}
	}
}
