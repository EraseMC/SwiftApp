import AppIntents
import EraseKit
import EraseUI
import SwiftUI
import WidgetKit

@main
struct EraseWidgets: WidgetBundle {
	var body: some Widget {
		ServerWidget()
		PlayerWidget()
		PlayControl()
	}
}

// MARK: - Server

struct ServerEntry: TimelineEntry {
	let date: Date
	let status: NetworkStatus?
}

struct ServerProvider: TimelineProvider {

	func placeholder(in context: Context) -> ServerEntry {
		ServerEntry(date: .now, status: nil)
	}

	func getSnapshot(in context: Context, completion: @escaping @Sendable (ServerEntry) -> Void) {
		Task { completion(await entry()) }
	}

	func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ServerEntry>) -> Void) {
		Task {
			// WidgetKit budgets refreshes; every 15 minutes is the most it reliably grants.
			completion(Timeline(entries: [await entry()], policy: .after(.now.addingTimeInterval(15 * 60))))
		}
	}

	private func entry() async -> ServerEntry {
		ServerEntry(date: .now, status: try? await APIClient.production.send(API.networkStatus))
	}
}

struct ServerWidget: Widget {
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: "server", provider: ServerProvider()) { entry in
			ServerWidgetView(entry: entry)
				.containerBackground(Palette.background, for: .widget)
				.widgetURL(URL(string: "erasemc://home"))
		}
		.configurationDisplayName("Erase online")
		.description("Players on the server right now.")
		.supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
	}
}

struct ServerWidgetView: View {

	let entry: ServerEntry

	@Environment(\.widgetFamily) private var family

	var body: some View {
		let online = entry.status?.online.map(String.init) ?? "—"

		switch family {
		case .accessoryCircular:
			Gauge(value: Double(entry.status?.online ?? 0), in: 0...Double(max(1, entry.status?.maxPlayers ?? 1))) {
				Text(verbatim: "E")
			} currentValueLabel: {
				Text(verbatim: online)
			}
			.gaugeStyle(.accessoryCircular)
		case .accessoryRectangular:
			VStack(alignment: .leading) {
				Text(verbatim: "Erase").font(.headline)
				Text("\(online) online").font(.body.monospacedDigit())
			}
		case .accessoryInline:
			Text("Erase · \(online) online")
		default:
			VStack(alignment: .leading, spacing: 6) {
				HStack(spacing: 6) {
					Circle()
						.fill(entry.status?.isReachable == true ? Palette.win : Palette.text3)
						.frame(width: 7, height: 7)
					Text(verbatim: "ERASE")
						.font(.caption.weight(.heavy))
						.foregroundStyle(Palette.accent)
					Spacer()
					if family == .systemMedium, let version = entry.status?.version {
						Text(verbatim: version).font(.caption2.monospacedDigit()).foregroundStyle(Palette.text3)
					}
				}
				Spacer()
				Text(verbatim: online)
					.font(.system(size: 44, weight: .bold, design: .monospaced))
					.foregroundStyle(Palette.text)
					.contentTransition(.numericText())
					.minimumScaleFactor(0.6)
				Text("online now")
					.font(.caption)
					.foregroundStyle(Palette.text2)
				if family == .systemMedium {
					Text(verbatim: entry.status?.address ?? "erasemc.com")
						.font(.caption.monospaced())
						.foregroundStyle(Palette.text3)
				}
			}
		}
	}
}

// MARK: - Player

struct PlayerIntent: WidgetConfigurationIntent {
	static let title: LocalizedStringResource = "Player"
	static let description = IntentDescription("Shows a player's rating.")

	@Parameter(title: "Player name", default: "")
	var name: String
}

struct PlayerEntry: TimelineEntry {
	let date: Date
	let name: String
	let profile: PlayerProfile?
	let head: UIImage?
}

struct PlayerProvider: AppIntentTimelineProvider {

	func placeholder(in context: Context) -> PlayerEntry {
		PlayerEntry(date: .now, name: "Steve", profile: nil, head: nil)
	}

	func snapshot(for configuration: PlayerIntent, in context: Context) async -> PlayerEntry {
		await entry(for: configuration.name)
	}

	func timeline(for configuration: PlayerIntent, in context: Context) async -> Timeline<PlayerEntry> {
		Timeline(entries: [await entry(for: configuration.name)], policy: .after(.now.addingTimeInterval(30 * 60)))
	}

	private func entry(for name: String) async -> PlayerEntry {
		let name = name.trimmingCharacters(in: .whitespaces)
		guard !name.isEmpty else {
			return PlayerEntry(date: .now, name: "", profile: nil, head: nil)
		}
		let profile = try? await APIClient.production.send(API.player(name))
		// Widgets cannot load images asynchronously while rendering, so the head is fetched here.
		let head = try? await URLSession.shared.data(from: API.skinURL(name, part: .head, size: 64)).0
		return PlayerEntry(date: .now, name: profile?.player.name ?? name, profile: profile, head: head.flatMap(UIImage.init(data:)))
	}
}

struct PlayerWidget: Widget {
	var body: some WidgetConfiguration {
		AppIntentConfiguration(kind: "player", intent: PlayerIntent.self, provider: PlayerProvider()) { entry in
			PlayerWidgetView(entry: entry)
				.containerBackground(Palette.background, for: .widget)
				.widgetURL(entry.name.isEmpty ? nil : URL(string: "erasemc://player/\(entry.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? entry.name)"))
		}
		.configurationDisplayName("Player")
		.description("A player's global Elo and place.")
		.supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
	}
}

struct PlayerWidgetView: View {

	let entry: PlayerEntry

	@Environment(\.widgetFamily) private var family

	var body: some View {
		if entry.name.isEmpty {
			Text("Edit the widget and enter a player name.")
				.font(.caption)
				.foregroundStyle(Palette.text2)
		} else if family == .accessoryRectangular {
			VStack(alignment: .leading) {
				Text(verbatim: entry.name).font(.headline)
				Text(verbatim: "Elo \(entry.profile?.ranked.elo.map(String.init) ?? "—") · #\(entry.profile?.ranked.place.map(String.init) ?? "—")")
					.font(.body.monospacedDigit())
			}
		} else {
			VStack(alignment: .leading, spacing: 6) {
				HStack(spacing: 8) {
					if let head = entry.head {
						Image(uiImage: head).resizable().interpolation(.none).frame(width: 28, height: 28).clipShape(.rect(cornerRadius: 5))
					}
					Text(verbatim: entry.name)
						.font(.subheadline.weight(.bold))
						.foregroundStyle(entry.profile?.player.rank.tint ?? Palette.text)
						.lineLimit(1)
				}
				Spacer()
				Text(verbatim: entry.profile?.ranked.elo.map(String.init) ?? "—")
					.font(.system(size: 34, weight: .bold, design: .monospaced))
					.foregroundStyle(Palette.accent)
				HStack {
					Text(verbatim: entry.profile?.ranked.place.map { "#\($0)" } ?? "—")
					if let ranked = entry.profile?.ranked {
						Text(verbatim: "\(ranked.wins)W \(ranked.losses)L")
					}
				}
				.font(.caption.monospacedDigit())
				.foregroundStyle(Palette.text2)
			}
		}
	}
}

// MARK: - Control Center

/// One tap from Control Center or the Lock Screen to open Minecraft with Erase added.
struct PlayControl: ControlWidget {
	var body: some ControlWidgetConfiguration {
		StaticControlConfiguration(kind: "play") {
			ControlWidgetButton(action: OpenErase()) {
				Label("Play Erase", systemImage: "play.fill")
			}
		}
		.displayName("Play Erase")
		.description("Opens Minecraft with the Erase server.")
	}
}

struct OpenErase: AppIntent {
	static let title: LocalizedStringResource = "Play Erase"

	func perform() async throws -> some IntentResult & OpensIntent {
		.result(opensIntent: OpenURLIntent(URL(string: "minecraft://?addExternalServer=Erase%7Cerasemc.com:19132")!))
	}
}
