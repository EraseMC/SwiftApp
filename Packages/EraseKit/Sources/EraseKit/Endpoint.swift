import Foundation

/// One API call: a path below `/api/v1/` and the type it answers with.
public struct Endpoint<Response: Decodable & Sendable>: Sendable {

	public enum Method: String, Sendable {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
	}

	public let path: String

	public let method: Method

	public let query: [URLQueryItem]

	public init(_ path: String, method: Method = .get, query: [URLQueryItem] = []) {
		self.path = path
		self.method = method
		self.query = query
	}

	func request(relativeTo base: URL) throws(APIError) -> URLRequest {
		guard var components = URLComponents(url: base.appending(path: path), resolvingAgainstBaseURL: false) else {
			throw .transport("Bad path \(path)")
		}

		if !query.isEmpty {
			components.queryItems = query
		}

		guard let url = components.url else {
			throw .transport("Bad path \(path)")
		}

		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		return request
	}
}
