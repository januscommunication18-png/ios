import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String
    let data: T?
    let errors: [String: [String]]?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case errors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        data = try container.decodeIfPresent(T.self, forKey: .data)
        errors = try container.decodeIfPresent([String: [String]].self, forKey: .errors)
    }
}

struct EmptyResponse: Decodable {}

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let meta: PaginationMeta?

    struct PaginationMeta: Decodable {
        let currentPage: Int
        let lastPage: Int
        let perPage: Int
        let total: Int

        enum CodingKeys: String, CodingKey {
            case currentPage = "current_page"
            case lastPage = "last_page"
            case perPage = "per_page"
            case total
        }
    }
}
