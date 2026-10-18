import CryptoKit
import Foundation

/// The last good body of every GET, on disk, so screens still show something without a network.
/// Only public reads are kept: anything sent with a session token stays out of the cache.
public struct ResponseCache: Sendable {

	private let directory: URL

	public init(directory: URL) {
		self.directory = directory
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
	}

	/// In the system Caches folder, which iOS may clear when space runs low.
	public static let shared = ResponseCache(
		directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "imprint")
	)

	func store(_ data: Data, for url: URL) {
		try? data.write(to: file(for: url), options: .atomic)
	}

	func data(for url: URL) -> Data? {
		try? Data(contentsOf: file(for: url))
	}

	private func file(for url: URL) -> URL {
		let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
		return directory.appending(path: digest.map { String(format: "%02x", $0) }.joined())
	}
}
