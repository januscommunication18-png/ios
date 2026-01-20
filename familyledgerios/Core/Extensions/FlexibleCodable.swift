import Foundation

// Helper type that can decode from either a string or a number
// Used for API fields that may return numeric values as strings (e.g., "1500.00")
enum StringOrDouble: Codable, Equatable {
    case string(String)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(StringOrDouble.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Double"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }

    var doubleValue: Double? {
        switch self {
        case .string(let str):
            return Double(str)
        case .double(let value):
            return value
        }
    }
}

// Helper type that can decode from either a string or an integer
enum StringOrInt: Codable, Equatable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(StringOrInt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }

    var intValue: Int? {
        switch self {
        case .string(let str):
            return Int(str)
        case .int(let value):
            return value
        }
    }
}
