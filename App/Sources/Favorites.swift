import CoreSpotlight
import EraseKit
import Foundation
import UniformTypeIdentifiers

/// Players the user follows. Kept on the device, shown on Home and findable from Spotlight.
@MainActor
@Observable
final class Favorites {

	private(set) var names: [String]

	private let key = "favorites"

	init() {
		names = UserDefaults.standard.stringArray(forKey: key) ?? []
	}

	func contains(_ name: String) -> Bool {
		names.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
	}

	func toggle(_ name: String) {
		if contains(name) {
			names.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
		} else {
			names.insert(name, at: 0)
		}
		UserDefaults.standard.set(names, forKey: key)
	}

	func move(from source: IndexSet, to destination: Int) {
		names.move(fromOffsets: source, toOffset: destination)
		UserDefaults.standard.set(names, forKey: key)
	}
}

/// Profiles the user opened become Spotlight results that open straight in the app.
enum PlayerSpotlight {

	static let domain = "com.erasemc.app.players"

	static func index(_ profile: PlayerProfile) {
		let attributes = CSSearchableItemAttributeSet(contentType: .content)
		attributes.title = profile.player.name
		attributes.displayName = profile.player.name
		var details = [profile.player.rank.displayName]
		if let elo = profile.ranked.elo {
			details.append("Elo \(elo)")
		}
		if let club = profile.club {
			details.append("[\(club.tag)] \(club.name)")
		}
		attributes.contentDescription = details.joined(separator: " · ")
		attributes.keywords = ["Erase", "Minecraft", profile.player.rank.displayName]

		let item = CSSearchableItem(uniqueIdentifier: profile.player.name, domainIdentifier: domain, attributeSet: attributes)
		item.expirationDate = .now.addingTimeInterval(60 * 60 * 24 * 60)
		CSSearchableIndex.default().indexSearchableItems([item]) { _ in }
	}
}
