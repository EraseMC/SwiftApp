import Foundation

extension JSONDecoder {

	/// Decodes Imprint's Jackson output: epoch seconds for stored timestamps,
	/// ISO-8601 instants with up to nanosecond fractions for `Instant` fields.
	public static var imprint: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .custom { decoder in
			let container = try decoder.singleValueContainer()

			if let seconds = try? container.decode(Double.self) {
				return Date(timeIntervalSince1970: seconds)
			}

			let text = try container.decode(String.self)

			guard let date = ImprintDate.parse(text) else {
				throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an ISO-8601 instant: \(text)")
			}

			return date
		}
		return decoder
	}
}

enum ImprintDate {

	/// Java's `Instant` prints up to nine fraction digits, more than Foundation's parsers accept,
	/// so the fraction is read separately and the rest goes through the plain ISO-8601 parser.
	static func parse(_ text: String) -> Date? {
		guard let dot = text.firstIndex(of: ".") else {
			return try? Date(text, strategy: .iso8601)
		}

		let digits = text[text.index(after: dot)...].prefix(while: \.isNumber)
		let rest = text[digits.endIndex...]

		guard let whole = try? Date(String(text[..<dot]) + rest, strategy: .iso8601) else {
			return nil
		}

		let fraction = Double("0." + digits) ?? 0
		return whole.addingTimeInterval(fraction)
	}
}
