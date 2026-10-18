import Foundation

/// Talks to the Imprint Web API, the same one erasemc.com renders from.
public final class APIClient: Sendable {

	public static let production = APIClient(
		baseURL: URL(string: "https://erasemc.com/api/v1/")!,
		credentials: Credentials(keychain: "com.erasemc.app.session")
	)

	public let baseURL: URL

	private let session: URLSession

	private let decoder: JSONDecoder

	/// The signed-in session's token, sent as a bearer token on every call.
	public let credentials: Credentials

	public init(baseURL: URL, session: URLSession = .shared, credentials: Credentials = Credentials()) {
		self.baseURL = baseURL
		self.session = session
		self.credentials = credentials
		self.decoder = .imprint
	}

	public func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws(APIError) -> Response {
		var request = try endpoint.request(relativeTo: baseURL)
		if let token = credentials.token {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		let data: Data
		let response: URLResponse

		do {
			(data, response) = try await session.data(for: request)
		} catch let error as URLError where error.code == .cancelled {
			throw .cancelled
		} catch {
			throw .transport(error.localizedDescription)
		}

		guard let http = response as? HTTPURLResponse else {
			throw .transport("No HTTP response")
		}

		guard (200..<300).contains(http.statusCode) else {
			let problem = try? decoder.decode(Problem.self, from: data)
			throw .status(http.statusCode, problem?.detail ?? problem?.title)
		}

		do {
			return try decoder.decode(Response.self, from: data)
		} catch {
			throw .decoding(String(describing: error))
		}
	}
}

/// Spring's RFC 9457 problem body, sent with every error status.
private struct Problem: Decodable {
	let title: String?
	let detail: String?
}
