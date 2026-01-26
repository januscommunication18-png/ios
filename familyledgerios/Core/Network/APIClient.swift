import Foundation

@Observable
final class APIClient {
    static let shared = APIClient()

//private let baseURL = "https://meetfamilyhub.com/api/v1"
private let baseURL = "http://127.0.0.1:8000/api/v1"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let timeout: TimeInterval = 30

    var onUnauthorized: (() -> Void)?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        // Don't use automatic snake_case conversion - we have explicit CodingKeys
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        // Don't use automatic snake_case conversion - we have explicit CodingKeys
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Request Methods

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        return try await performRequest(request, endpoint: endpoint)
    }

    func request<T: Decodable, B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        request.httpBody = try encoder.encode(body)
        return try await performRequest(request, endpoint: endpoint)
    }

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        bodyDict: [String: Any],
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
        return try await performRequest(request, endpoint: endpoint)
    }

    func requestWithResponse<T: Decodable>(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> APIResponse<T> {
        let request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        return try await performRequestWithResponse(request, endpoint: endpoint)
    }

    func requestWithResponse<T: Decodable, B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> APIResponse<T> {
        var request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        request.httpBody = try encoder.encode(body)
        return try await performRequestWithResponse(request, endpoint: endpoint)
    }

    func requestEmpty(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        let request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        let _: EmptyResponse = try await performRequest(request, endpoint: endpoint)
    }

    func requestEmpty<B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        var request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        request.httpBody = try encoder.encode(body)
        let _: EmptyResponse = try await performRequest(request, endpoint: endpoint)
    }

    // MARK: - Multipart Form Data

    func uploadMultipart<T: Decodable>(
        _ endpoint: APIEndpoint,
        parameters: [String: Any],
        fileData: Data?,
        fileName: String?,
        mimeType: String?
    ) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, queryItems: nil)

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add file if present
        if let fileData = fileData, let fileName = fileName, let mimeType = mimeType {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        return try await performRequest(request, endpoint: endpoint)
    }

    // MARK: - Private Methods

    private func buildRequest(endpoint: APIEndpoint, queryItems: [URLQueryItem]?) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add auth token only if endpoint requires authentication
        if endpoint.requiresAuth, let token = KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest, endpoint: APIEndpoint) async throws -> T {
        print("DEBUG API: Making request to \(request.url?.absoluteString ?? "nil")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("DEBUG API: Invalid response (not HTTP)")
            throw APIError.invalidResponse
        }

        print("DEBUG API: Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("DEBUG API: Response body: \(responseString.prefix(500))")
        }

        try handleStatusCode(httpResponse.statusCode, data: data, endpoint: endpoint)

        do {
            // Try to decode as APIResponse first
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
            if apiResponse.success, let responseData = apiResponse.data {
                print("DEBUG API: Successfully decoded response")
                return responseData
            } else if let errors = apiResponse.errors {
                print("DEBUG API: Validation errors: \(errors)")
                throw APIError.validationError(errors: errors)
            } else {
                print("DEBUG API: Server error: \(apiResponse.message)")
                throw APIError.serverError(message: apiResponse.message)
            }
        } catch let decodingError as DecodingError {
            print("DEBUG API: Decoding error: \(decodingError)")
            // If APIResponse decoding fails, try direct decoding
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(decodingError)
            }
        }
    }

    private func performRequestWithResponse<T: Decodable>(_ request: URLRequest, endpoint: APIEndpoint) async throws -> APIResponse<T> {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try handleStatusCode(httpResponse.statusCode, data: data, endpoint: endpoint)

        do {
            return try decoder.decode(APIResponse<T>.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func handleStatusCode(_ statusCode: Int, data: Data, endpoint: APIEndpoint) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            // Only trigger onUnauthorized for authenticated endpoints
            // For public endpoints like login, 401 means invalid credentials
            if endpoint.requiresAuth {
                DispatchQueue.main.async { [weak self] in
                    self?.onUnauthorized?()
                }
                throw APIError.unauthorized
            } else {
                // For login/auth endpoints, throw a more appropriate error
                if let apiResponse = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data) {
                    throw APIError.serverError(message: apiResponse.message)
                }
                throw APIError.serverError(message: "Invalid credentials")
            }
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            // Validation error - try to parse errors
            if let apiResponse = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data),
               let errors = apiResponse.errors {
                throw APIError.validationError(errors: errors)
            }
            throw APIError.invalidData
        case 500...599:
            if let apiResponse = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data) {
                throw APIError.serverError(message: apiResponse.message)
            }
            throw APIError.serverError(message: "Server error occurred")
        default:
            throw APIError.unknown(statusCode: statusCode)
        }
    }
}

// MARK: - Helper Extensions

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
