import Fluent

struct CreateListing: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema(Listing.schema)
			.id()
			.field("title", .string, .required)
			.field("description", .string, .required)
			.field("price", .double, .required)
			.field("category", .string, .required)
			.field("seller_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
			.field("created_at", .datetime)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema(Listing.schema).delete()
	}
}
