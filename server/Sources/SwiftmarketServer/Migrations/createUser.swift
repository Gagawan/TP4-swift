import Fluent

struct CreateUser: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema(User.schema)
			.id()
			.field("username", .string, .required)
			.field("email", .string, .required)
			.field("created_at", .datetime)
			.unique(on: "username")
			.unique(on: "email")
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema(User.schema).delete()
	}
}
