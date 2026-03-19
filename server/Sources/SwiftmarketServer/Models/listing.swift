import Fluent
import Vapor

final class Listing: Model, Content, @unchecked Sendable {
	static let schema = "listings"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "title")
	var title: String

	@Field(key: "description")
	var description: String

	@Field(key: "price")
	var price: Double

	@Field(key: "category")
	var category: String

	@Parent(key: "seller_id")
	var seller: User

	@Timestamp(key: "created_at", on: .create)
	var createdAt: Date?

	init() {}

	init(
		id: UUID? = nil,
		title: String,
		description: String,
		price: Double,
		category: String,
		sellerID: UUID,
		createdAt: Date? = nil
	) {
		self.id = id
		self.title = title
		self.description = description
		self.price = price
		self.category = category
		self.$seller.id = sellerID
		self.createdAt = createdAt
	}
}
