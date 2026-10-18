import Foundation

public enum APIError: Error, Equatable, Sendable {

	/// The request never got an HTTP answer: offline, timeout, TLS.
	case transport(String)

	/// Imprint answered with a non-2xx status and, usually, a problem detail.
	case status(Int, String?)

	/// The body did not match the model, which means the app and API drifted apart.
	case decoding(String)

	case cancelled

	public var isNotFound: Bool {
		if case .status(404, _) = self {
			return true
		}
		return false
	}

	/// A short line for the screen. Problem details from Imprint are already written for people.
	public var message: String {
		switch self {
		case .transport(let message): message
		case .status(let code, let detail): detail ?? "HTTP \(code)"
		case .decoding: "Unexpected response from the server"
		case .cancelled: "Cancelled"
		}
	}
}
