import Foundation

/// A decoder that parses dates the way PostgREST hands them to us.
///
/// Postgres renders `timestamptz` with **microsecond** precision, e.g.
/// `2026-08-18T14:32:58.123456+00:00`. Foundation's `.iso8601` strategy
/// rejects that outright, and `ISO8601DateFormatter` with
/// `.withFractionalSeconds` only copes with three fractional digits — so a
/// naive decoder passes in a test and fails against the live database.
///
/// The formats below are tried in order, covering the shapes Postgres
/// actually emits depending on whether the value has sub-second precision.
enum PostgrestFixture {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            for formatter in formatters {
                if let date = formatter.date(from: raw) { return date }
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised Postgres timestamp: \(raw)"
            )
        }
        return decoder
    }()

    private static let formatters: [DateFormatter] = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
        "yyyy-MM-dd'T'HH:mm:ssXXXXX",
    ].map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    /// Decode a fixture written as a Swift string literal.
    static func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try decoder.decode(type, from: Data(json.utf8))
    }
}
