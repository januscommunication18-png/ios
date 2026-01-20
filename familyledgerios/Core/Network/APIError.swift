import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case unauthorized
    case forbidden
    case notFound
    case validationError(errors: [String: [String]])
    case serverError(message: String)
    case networkError(Error)
    case decodingError(Error)
    case unknown(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .unauthorized:
            return "Session expired. Please login again."
        case .forbidden:
            return "You don't have permission to access this resource"
        case .notFound:
            return "Resource not found"
        case .validationError(let errors):
            let messages = errors.flatMap { $0.value }
            return messages.joined(separator: "\n")
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .unknown(let statusCode):
            return "Unknown error occurred (Status: \(statusCode))"
        }
    }

    var isUnauthorized: Bool {
        if case .unauthorized = self {
            return true
        }
        return false
    }
}
