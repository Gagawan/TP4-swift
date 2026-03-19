import Fluent
import Vapor

struct CreateListingRequest: Content, Validatable {
    var title: String
    var description: String
    var price: Double
    var category: String
    var sellerID: UUID

    static let allowedCategories = ["electronics", "clothing", "furniture", "other"]

    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: .count(1...))
        validations.add("price", as: Double.self, is: .range(0.000_000_1...Double.greatestFiniteMagnitude))
        validations.add("category", as: String.self, is: .count(1...))
    }
}

struct ListingResponse: Content {
    var id: UUID
    var title: String
    var description: String
    var price: Double
    var category: String
    var seller: UserResponse
    var createdAt: Date?

    init(listing: Listing) throws {
        guard listing.$seller.value != nil else {
            throw Abort(.internalServerError, reason: "Listing seller is not loaded")
        }

        guard let id = listing.id else {
            throw Abort(.internalServerError, reason: "Listing ID is missing")
        }

        self.id = id
        self.title = listing.title
        self.description = listing.description
        self.price = listing.price
        self.category = listing.category
        self.seller = try UserResponse(user: listing.seller)
        self.createdAt = listing.createdAt
    }
}

struct PagedListingResponse: Content {
    var items: [ListingResponse]
    var page: Int
    var totalPages: Int
    var totalCount: Int
}

