import Fluent
import Vapor

struct CreateUserRequest: Content, Validatable {
    var username: String
    var email: String

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .count(1...))
        validations.add("email", as: String.self, is: .email)
    }
}

struct UserResponse: Content {
    var id: UUID
    var username: String
    var email: String
    var createdAt: Date?

    init(user: User) throws {
        guard let id = user.id else {
            throw Abort(.internalServerError, reason: "User ID is missing")
        }

        self.id = id
        self.username = user.username
        self.email = user.email
        self.createdAt = user.createdAt
    }
}