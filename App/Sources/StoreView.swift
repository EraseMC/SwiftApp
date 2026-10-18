import EraseKit
import EraseUI
import SafariServices
import SwiftUI

struct StoreView: View {

	@State private var categories: Phase<[StoreCategory]> = .loading

	@State private var purchases: [StorePurchase] = []

	@State private var selected: StoreItem?

	private let store = StoreClient.production

	var body: some View {
		ScrollView {
			LoadState(categories, retry: load) { categories in
				VStack(alignment: .leading, spacing: Space.s5) {
					if !purchases.isEmpty {
						recent
					}
					ForEach(categories) { category in
						VStack(alignment: .leading, spacing: Space.s3) {
							Text(verbatim: category.name).font(.eraseTitle3)
							LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
								ForEach(category.items) { item in
									Button { selected = item } label: {
										ItemCard(item: item)
									}
									.buttonStyle(.pressable)
								}
							}
						}
					}
				}
				.padding(Space.s4)
				.readableWidth()
			}
		}
		.background(Palette.background)
		.navigationTitle(Copy.text("nav.store"))
		.refreshable { await load() }
		.task { await load() }
		.sheet(item: $selected) { item in
			PurchaseSheet(item: item, store: store)
				.presentationDetents([.medium, .large])
		}
	}

	private var recent: some View {
		ScrollView(.horizontal) {
			HStack(spacing: Space.s2) {
				ForEach(Array(purchases.prefix(12).enumerated()), id: \.offset) { _, purchase in
					HStack(spacing: Space.s2) {
						PlayerHead(purchase.buyer, size: 22)
						VStack(alignment: .leading, spacing: 0) {
							Text(verbatim: purchase.buyer).font(.eraseCaption.weight(.semibold))
							Text(verbatim: purchase.item.name)
								.font(.eraseCaption)
								.foregroundStyle(Palette.text3)
								.lineLimit(1)
						}
					}
					.padding(.horizontal, Space.s3)
					.padding(.vertical, Space.s2)
					.background(Palette.surface, in: .capsule)
				}
			}
		}
		.scrollIndicators(.hidden)
	}

	private func load() async {
		do throws(APIError) {
			let fresh = try await store.categories()
			withAnimation(Motion.popover) { categories = .loaded(fresh) }
		} catch .cancelled {
			return
		} catch {
			categories = .failed(error)
		}
		purchases = (try? await store.lastPurchases()) ?? []
	}
}

private struct ItemCard: View {

	let item: StoreItem

	var body: some View {
		VStack(alignment: .leading, spacing: Space.s2) {
			AsyncImage(url: item.image) { image in
				image.resizable().aspectRatio(1, contentMode: .fill)
			} placeholder: {
				Palette.surfaceActive
			}
			.aspectRatio(1, contentMode: .fit)
			.clipShape(.rect(cornerRadius: Radius.sm))

			Text(verbatim: item.name)
				.font(.eraseFootnote.weight(.semibold))
				.foregroundStyle(Palette.text)
				.lineLimit(2, reservesSpace: true)
			Text(item.cost, format: .currency(code: "RUB").precision(.fractionLength(0)))
				.font(.eraseNumber.weight(.bold))
				.foregroundStyle(Palette.accentText)
		}
		.panel(padding: Space.s2)
	}
}

private struct PurchaseSheet: View {

	let item: StoreItem

	let store: StoreClient

	@Environment(AuthModel.self) private var auth

	@State private var nickname = ""

	@State private var busy = false

	@State private var error: String?

	@State private var checkout: URL?

	var body: some View {
		NavigationStack {
			Form {
				Section {
					HStack(spacing: Space.s3) {
						AsyncImage(url: item.image) { $0.resizable() } placeholder: { Palette.surfaceActive }
							.frame(width: 64, height: 64)
							.clipShape(.rect(cornerRadius: Radius.sm))
						VStack(alignment: .leading) {
							Text(verbatim: item.name).font(.eraseHeadline)
							Text(item.cost, format: .currency(code: "RUB").precision(.fractionLength(0)))
								.font(.eraseNumber.weight(.bold))
								.foregroundStyle(Palette.accentText)
						}
					}
					if let description = item.description, !description.isEmpty {
						Text(verbatim: description)
							.font(.eraseFootnote)
							.foregroundStyle(Palette.text2)
					}
				}

				Section {
					TextField("Player name", text: $nickname)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.font(.eraseNumber)
				} footer: {
					Text("Goods are delivered to this player on the server.")
				}

				if let error {
					Text(verbatim: error).foregroundStyle(Palette.loss).font(.eraseFootnote)
				}

				Section {
					Button {
						Task { await buy() }
					} label: {
						HStack {
							if busy { ProgressView() }
							Text("Buy")
						}
						.frame(maxWidth: .infinity)
					}
					.disabled(busy || nickname.trimmingCharacters(in: .whitespaces).count < 2)
				}
			}
			.navigationTitle(Copy.text("nav.store"))
			.navigationBarTitleDisplayMode(.inline)
		}
		.onAppear { nickname = auth.playerName ?? nickname }
		.fullScreenCover(item: $checkout) { url in
			SafariView(url: url).ignoresSafeArea()
		}
	}

	private func buy() async {
		busy = true
		error = nil
		defer { busy = false }

		do throws(APIError) {
			checkout = try await store.checkoutURL(item: item.id, nickname: nickname.trimmingCharacters(in: .whitespaces))
		} catch {
			self.error = switch error {
			case .status(404, "unknownPlayer"): String(localized: "No player with this name has joined Erase.")
			case .status(_, "invalidRequest"): String(localized: "Check the player name.")
			default: String(localized: "The store is unavailable right now. Try again later.")
			}
		}
	}
}

extension URL: @retroactive Identifiable {
	public var id: String { absoluteString }
}

/// TradeMC's checkout inside the app, so the buyer returns here when payment is done.
struct SafariView: UIViewControllerRepresentable {

	let url: URL

	func makeUIViewController(context: Context) -> SFSafariViewController {
		let controller = SFSafariViewController(url: url)
		controller.preferredControlTintColor = UIColor(red: 0.66, green: 0.94, blue: 0.22, alpha: 1)
		controller.dismissButtonStyle = .close
		return controller
	}

	func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
