import Foundation

struct UserResponse: Codable {
    var id: UUID
    var username: String
    var email: String
    var createdAt: Date?
}

struct CreateUserRequest: Codable {
    var username: String
    var email: String
}

struct ListingResponse: Codable {
    var id: UUID
    var title: String
    var description: String
    var price: Double
    var category: String
    var seller: UserResponse
    var createdAt: Date?
}

struct CreateListingRequest: Codable {
    var title: String
    var description: String
    var price: Double
    var category: String
    var sellerID: UUID
}

struct PagedListingResponse: Codable {
    var items: [ListingResponse]
    var page: Int
    var totalPages: Int
    var totalCount: Int
}

struct ServerError: Codable {
    var reason: String?
    var error: Bool?
}