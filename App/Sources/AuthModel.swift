import AuthenticationServices
import CryptoKit
import EraseKit
import Foundation
import SwiftUI

/// The signed-in account. Sign-in runs Microsoft's page in a web authentication session;
/// Imprint answers with a one-time ticket that only this app's PKCE verifier can redeem.
@MainActor
@Observable
final class AuthModel {

	enum Failure: Equatable {
		case cancelled
		case xbox
		case failed
		case linkFailed
	}

	private(set) var identity: AuthIdentity?

	private(set) var linkCode: AuthLinkCode?

	private(set) var busy = false

	var failure: Failure?

	private let api: APIClient

	init(api: APIClient) {
		self.api = api
	}

	var isSignedIn: Bool { identity?.authenticated == true }

	/// The linked game player, nil until `/link` has been run.
	var playerName: String? { identity?.playerName }

	var staffRole: String? { identity?.staff }

	func refresh() async {
		guard case .loaded(let fresh) = await api.phase(API.me) else { return }
		if !fresh.authenticated, api.credentials.token != nil {
			// The session expired or was revoked on the server.
			api.credentials.store(nil)
		}
		identity = fresh
		if fresh.playerName != nil {
			linkCode = nil
		}
	}

	func signIn(with session: WebAuthenticationSession) async {
		failure = nil
		busy = true
		defer { busy = false }

		let verifier = Self.randomVerifier()
		let challenge = Self.challenge(for: verifier)

		let callback: URL
		do {
			callback = try await session.authenticate(
				using: API.signInURL(challenge: challenge),
				callbackURLScheme: "erasemc",
				preferredBrowserSession: .ephemeral
			)
		} catch {
			failure = .cancelled
			return
		}

		let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
		if let error = items.first(where: { $0.name == "error" })?.value {
			failure = error == "xbox" ? .xbox : error == "cancelled" ? .cancelled : .failed
			return
		}
		guard let ticket = items.first(where: { $0.name == "ticket" })?.value else {
			failure = .failed
			return
		}

		guard case .loaded(let session) = await api.phase(API.appToken(ticket: ticket, verifier: verifier)) else {
			failure = .failed
			return
		}
		api.credentials.store(session.token)
		await refresh()
	}

	func requestLinkCode() async {
		failure = nil
		if case .loaded(let code) = await api.phase(API.linkCode) {
			linkCode = code
		} else {
			failure = .linkFailed
		}
	}

	func signOut() async {
		_ = await api.phase(API.logout)
		api.credentials.store(nil)
		identity = AuthIdentity(configured: identity?.configured ?? true, authenticated: false, playerName: nil, staff: nil)
		linkCode = nil
	}

	private static func randomVerifier() -> String {
		var bytes = [UInt8](repeating: 0, count: 32)
		_ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		return base64URL(Data(bytes))
	}

	private static func challenge(for verifier: String) -> String {
		base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
	}

	private static func base64URL(_ data: Data) -> String {
		data.base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
}
