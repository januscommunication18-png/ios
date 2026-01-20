import Foundation

struct Person: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let nickname: String?
    let relationship: String?
    let relationshipName: String?
    let customRelationship: String?
    let company: String?
    let jobTitle: String?
    let birthday: String?
    let birthdayRaw: String?
    let age: Int?
    let profileImageUrl: String?
    let primaryEmail: PersonEmail?
    let primaryPhone: PersonPhone?
    let tags: [String]?
    let notes: String?
    let howWeKnow: String?
    let visibility: String?
    let visibilityName: String?
    let source: String?
    let sourceName: String?
    let metAt: String?
    let metLocation: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, nickname, relationship, company, birthday, age, tags, notes, visibility, source
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case relationshipName = "relationship_name"
        case customRelationship = "custom_relationship"
        case jobTitle = "job_title"
        case birthdayRaw = "birthday_raw"
        case profileImageUrl = "profile_image_url"
        case primaryEmail = "primary_email"
        case primaryPhone = "primary_phone"
        case howWeKnow = "how_we_know"
        case visibilityName = "visibility_name"
        case sourceName = "source_name"
        case metAt = "met_at"
        case metLocation = "met_location"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var initials: String {
        let first = firstName?.prefix(1) ?? ""
        let last = lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    static func == (lhs: Person, rhs: Person) -> Bool { lhs.id == rhs.id }
}

struct PersonEmail: Codable, Identifiable {
    let id: Int?
    let email: String?
    let label: String?
    let isPrimary: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email, label
        case isPrimary = "is_primary"
    }

    // Make id non-optional for Identifiable
    var wrappedId: Int { id ?? UUID().hashValue }
}

struct PersonPhone: Codable, Identifiable {
    let id: Int?
    let phone: String?
    let formattedPhone: String?
    let label: String?
    let isPrimary: Bool?

    enum CodingKeys: String, CodingKey {
        case id, phone, label
        case formattedPhone = "formatted_phone"
        case isPrimary = "is_primary"
    }

    var wrappedId: Int { id ?? UUID().hashValue }
}

struct PersonAddress: Codable, Identifiable {
    let id: Int
    let label: String?
    let street: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let fullAddress: String?
    let isPrimary: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label, street, city, state, country
        case postalCode = "postal_code"
        case fullAddress = "full_address"
        case isPrimary = "is_primary"
    }
}

struct PersonImportantDate: Codable, Identifiable {
    let id: Int
    let label: String?
    let date: String?
    let dateRaw: String?
    let isAnnual: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label, date
        case dateRaw = "date_raw"
        case isAnnual = "is_annual"
    }
}

struct PersonLink: Codable, Identifiable {
    let id: Int
    let label: String?
    let url: String?
}

struct PersonAttachment: Codable, Identifiable {
    let id: Int
    let name: String?
    let fileType: String?
    let mimeType: String?
    let fileSize: Int?
    let formattedSize: String?
    let isImage: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case fileType = "file_type"
        case mimeType = "mime_type"
        case fileSize = "file_size"
        case formattedSize = "formatted_size"
        case isImage = "is_image"
    }
}

struct PeopleResponse: Codable {
    let people: [Person]?
    let total: Int?
    let byRelationship: [String: Int]?

    enum CodingKeys: String, CodingKey {
        case people, total
        case byRelationship = "by_relationship"
    }
}

struct PersonDetailResponse: Codable {
    let person: Person?
    let emails: [PersonEmail]?
    let phones: [PersonPhone]?
    let addresses: [PersonAddress]?
    let importantDates: [PersonImportantDate]?
    let links: [PersonLink]?
    let attachments: [PersonAttachment]?
    let stats: PersonStats?

    enum CodingKeys: String, CodingKey {
        case person, emails, phones, addresses, links, attachments, stats
        case importantDates = "important_dates"
    }
}

struct PersonStats: Codable {
    let emails: Int?
    let phones: Int?
    let addresses: Int?
    let importantDates: Int?
    let attachments: Int?

    enum CodingKeys: String, CodingKey {
        case emails, phones, addresses, attachments
        case importantDates = "important_dates"
    }
}
