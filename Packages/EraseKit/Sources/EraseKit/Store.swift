import Foundation

/// The TradeMC shop. TradeMC holds the catalogue and takes the payment and delivers over RCON;
/// erasemc.com opens the cart so a mistyped nickname can never receive paid goods.
public struct StoreClient: Sendable {

	public static let production = StoreClient(
		shop: "242896",
		checkout: URL(string: "https://erasemc.com/api/store/checkout")!
	)

	public let shop: String

	public let checkout: URL

	private let api = URL(string: "https://api.trademc.org")!

	public init(shop: String, checkout: URL) {
		self.shop = shop
		self.checkout = checkout
	}

	public func categories() async throws(APIError) -> [StoreCategory] {
		let response: CatalogueResponse = try await call("getItems", ["shop": shop])
		return response.categories.filter { !$0.items.isEmpty }
	}

	public func lastPurchases() async throws(APIError) -> [StorePurchase] {
		try await call("getLastPurchases", ["shops": shop])
	}

	/// The TradeMC payment page for one item bought for `nickname`.
	public func checkoutURL(item: Int, nickname: String) async throws(APIError) -> URL {
		var request = URLRequest(url: checkout)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try? JSONEncoder().encode(CheckoutRequest(itemId: item, nickname: nickname))

		let (data, status) = try await load(request)
		guard (200..<300).contains(status) else {
			let problem = try? JSONDecoder().decode(CheckoutProblem.self, from: data)
			throw .status(status, problem?.error)
		}
		guard let answer = try? JSONDecoder().decode(CheckoutAnswer.self, from: data), let url = URL(string: answer.url) else {
			throw .decoding("No checkout URL")
		}
		return url
	}

	private func call<T: Decodable>(_ method: String, _ params: [String: String]) async throws(APIError) -> T {
		var url = api.appending(path: "shop.\(method)")
		url.append(queryItems: params.map { URLQueryItem(name: $0.key, value: $0.value) } + [URLQueryItem(name: "v", value: "3")])

		let (data, status) = try await load(URLRequest(url: url))
		guard (200..<300).contains(status) else {
			throw .status(status, nil)
		}
		do {
			let envelope = try JSONDecoder().decode(Envelope<T>.self, from: data)
			guard let response = envelope.response else {
				throw APIError.status(502, envelope.error?.message)
			}
			return response
		} catch let error as APIError {
			throw error
		} catch {
			throw .decoding(String(describing: error))
		}
	}

	private func load(_ request: URLRequest) async throws(APIError) -> (Data, Int) {
		do {
			let (data, response) = try await URLSession.shared.data(for: request)
			return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
		} catch let error as URLError where error.code == .cancelled {
			throw .cancelled
		} catch {
			throw .transport(error.localizedDescription)
		}
	}

	private struct Envelope<T: Decodable>: Decodable {
		let response: T?
		let error: Failure?

		struct Failure: Decodable {
			let message: String
		}
	}

	private struct CatalogueResponse: Decodable {
		let categories: [StoreCategory]
	}

	private struct CheckoutRequest: Encodable {
		let itemId: Int
		let nickname: String
	}

	private struct CheckoutAnswer: Decodable {
		let url: String
	}

	private struct CheckoutProblem: Decodable {
		/// `invalidRequest`, `unknownItem`, `unknownPlayer` or `unavailable`.
		let error: String
	}
}

public struct StoreItem: Decodable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let name: String
	/// Price in roubles.
	public let cost: Double
	public let description: String?
	public let image: URL?

	enum CodingKeys: String, CodingKey {
		case id, name, cost, description, image
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(Int.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		cost = try container.decode(Double.self, forKey: .cost)
		description = try container.decodeIfPresent(String.self, forKey: .description)
		// TradeMC sends "" for items without art.
		image = try container.decodeIfPresent(String.self, forKey: .image).flatMap { $0.isEmpty ? nil : URL(string: $0) }
	}
}

public struct StoreCategory: Decodable, Hashable, Sendable, Identifiable {
	public let id: Int
	public let name: String
	public let items: [StoreItem]
}

public struct StorePurchase: Decodable, Hashable, Sendable {
	public let buyer: String
	public let item: Item

	public struct Item: Decodable, Hashable, Sendable {
		public let id: Int
		public let name: String
		public let image: String?
	}
}
