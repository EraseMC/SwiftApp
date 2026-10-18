import EraseKit
import EraseUI
import SwiftUI

struct HomeView: View {

	@Environment(AppModel.self) private var model

	@Environment(\.openURL) private var openURL

	@State private var status: NetworkStatus?

	@State private var error: APIError?

	@State private var copied = false

	@State private var top: [LadderEntry] = []

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: Space.s4) {
				hero
				statusCard
				topThree
				modes
				community
			}
			.padding(Space.s4)
		}
		.background(Palette.background)
		.navigationTitle("Erase")
		.refreshable { await load() }
		.task {
			// Keep the counter live while the tab is on screen, like the site's live band.
			while !Task.isCancelled {
				await load()
				try? await Task.sleep(for: .seconds(30))
			}
		}
	}

	private var hero: some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			Text("Every ladder. One rating.")
				.font(.eraseHero)
				.foregroundStyle(Palette.text)
			Text("Ranked duels, tiers and tournaments for Minecraft: Bedrock Edition.")
				.font(.eraseCallout)
				.foregroundStyle(Palette.text2)
		}
		.padding(.vertical, Space.s2)
	}

	private var statusCard: some View {
		VStack(alignment: .leading, spacing: Space.s4) {
			HStack(alignment: .firstTextBaseline) {
				Circle()
					.fill(status?.isReachable == true ? Palette.win : Palette.text3)
					.frame(width: 8, height: 8)
				Text(status?.isReachable == false ? "Server offline" : "Online now")
					.font(.eraseFootnote.weight(.semibold))
					.foregroundStyle(Palette.text2)
				Spacer()
				if let version = status?.version {
					Text(version)
						.font(.eraseSmallNumber)
						.foregroundStyle(Palette.text3)
				}
			}

			HStack(alignment: .lastTextBaseline, spacing: Space.s2) {
				Text(status?.online.map(String.init) ?? "—")
					.font(Typeface.mono(48, .bold, relativeTo: .largeTitle))
					.contentTransition(.numericText())
					.foregroundStyle(Palette.text)
				if let max = status?.maxPlayers {
					Text("/ \(max)")
						.font(Typeface.mono(20, .medium, relativeTo: .title3))
						.foregroundStyle(Palette.text3)
				}
			}
			.animation(Motion.scope, value: status?.online)

			if let error, status == nil {
				Text(verbatim: error.message)
					.font(.eraseFootnote)
					.foregroundStyle(Palette.loss)
			}

			Button {
				UIPasteboard.general.string = address
				copied = true
			} label: {
				HStack {
					Text(verbatim: address)
						.font(.eraseNumber)
						.foregroundStyle(Palette.text)
					Spacer()
					Image(systemName: copied ? "checkmark" : "doc.on.doc")
						.foregroundStyle(copied ? Palette.win : Palette.text2)
						.contentTransition(.symbolEffect(.replace))
				}
				.padding(Space.s3)
				.background(Palette.sunken, in: .rect(cornerRadius: Radius.sm))
			}
			.buttonStyle(.pressable)
			.sensoryFeedback(.success, trigger: copied) { _, new in new }
			.task(id: copied) {
				guard copied else { return }
				try? await Task.sleep(for: .seconds(2))
				copied = false
			}

			Button {
				if let url = playURL {
					openURL(url)
				}
			} label: {
				Label("Play now", systemImage: "play.fill")
			}
			.buttonStyle(.erasePrimary)
		}
		.panel()
	}

	@ViewBuilder
	private var topThree: some View {
		if !top.isEmpty {
			SectionHeader(LocalizedStringKey(Copy.text("home.topThree")))
			HStack(spacing: Space.s3) {
				ForEach(top, id: \.place) { entry in
					NavigationLink(value: Route.player(entry.name)) {
						VStack(spacing: Space.s2) {
							PlayerHead(entry.name, size: 48)
							RankedName(entry.name, rank: entry.rank)
								.font(.eraseFootnote.weight(.semibold))
							Text(verbatim: "\(entry.elo ?? entry.wins)")
								.font(.eraseNumber.weight(.bold))
								.foregroundStyle(tierColor(entry.place))
						}
						.frame(maxWidth: .infinity)
						.panel(padding: Space.s3)
					}
					.buttonStyle(.pressable)
				}
			}
		}
	}

	private var modes: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			SectionHeader(LocalizedStringKey(Copy.text("home.modes.title")))
			LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Space.s2)], spacing: Space.s2) {
				ForEach(Mode.ladders) { mode in
					Button {
						UserDefaults.standard.set(mode.key.rawValue, forKey: "leaderboards.board")
						UserDefaults.standard.set("players", forKey: "leaderboards.scope")
						model.tab = .leaderboards
					} label: {
						VStack(spacing: Space.s2) {
							ModeIcon(mode, size: 36)
							Text(verbatim: mode.name)
								.font(.eraseCaption)
								.foregroundStyle(Palette.text2)
								.lineLimit(1)
								.minimumScaleFactor(0.8)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, Space.s3)
						.background(Palette.surface, in: .rect(cornerRadius: Radius.md))
						.overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.line))
					}
					.buttonStyle(.pressable)
				}
			}
		}
	}

	private var community: some View {
		VStack(alignment: .leading, spacing: Space.s3) {
			SectionHeader(LocalizedStringKey(Copy.text("home.community.title")))
			Text(Copy.text("home.community.body"))
				.font(.eraseCallout)
				.foregroundStyle(Palette.text2)
			HStack(spacing: Space.s2) {
				Link(destination: Links.discord) {
					Label("Discord", systemImage: "bubble.left.and.bubble.right.fill")
				}
				Link(destination: Links.telegram) {
					Label("Telegram", systemImage: "paperplane.fill")
				}
				Link(destination: Links.tiktok) {
					Label("TikTok", systemImage: "play.rectangle.fill")
				}
			}
			.font(.eraseFootnote.weight(.semibold))
			.buttonStyle(.bordered)
			.tint(Palette.text2)
		}
	}

	private var address: String {
		let host = status?.address ?? "erasemc.com"
		let port = status?.port ?? 19132
		return port == 19132 ? host : "\(host):\(port)"
	}

	/// Bedrock's URL scheme opens the game and offers to add the server to the list.
	private var playURL: URL? {
		var components = URLComponents()
		components.scheme = "minecraft"
		components.host = ""
		components.queryItems = [
			URLQueryItem(name: "addExternalServer", value: "Erase|\(status?.address ?? "erasemc.com"):\(status?.port ?? 19132)"),
		]
		return components.url
	}

	private func load() async {
		if top.isEmpty, case .loaded(let board) = await model.api.phase(API.leaderboard("global", limit: 3)) {
			top = board.entries
		}
		do throws(APIError) {
			let fresh = try await model.api.send(API.networkStatus)
			status = fresh
			error = nil
		} catch .cancelled {
			return
		} catch {
			self.error = error
		}
	}
}
