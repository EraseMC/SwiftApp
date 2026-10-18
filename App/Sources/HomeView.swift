import EraseKit
import EraseUI
import SwiftUI

struct HomeView: View {

	@Environment(AppModel.self) private var model

	@Environment(\.openURL) private var openURL

	@State private var status: NetworkStatus?

	@State private var error: APIError?

	@State private var copied = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: Space.s4) {
				hero
				statusCard
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
