import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.post(use: create)
        users.get(use: index)

        users.group(":id") { user in
            user.get(use: show)
            user.get("listings", use: listings)
        }
    }

    private func create(req: Request) async throws -> Response {
        do {
            try CreateUserRequest.validate(content: req)
        } catch {
            throw Abort(.unprocessableEntity, reason: "Validation failed.\n\(error.localizedDescription)")
        }

        let payload = try req.content.decode(CreateUserRequest.self)
        let user = User(username: payload.username, email: payload.email)

        do {
            try await user.save(on: req.db)
        } catch {
            throw Abort(.conflict, reason: "A user with this username or email already exists.")
        }

        let response = try UserResponse(user: user)
        return try await response.encodeResponse(status: .created, for: req)
    }

    private func index(req: Request) async throws -> [UserResponse] {
        let users = try await User.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()

        return try users.map(UserResponse.init)
    }

    private func show(req: Request) async throws -> UserResponse {
        guard let userID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        return try UserResponse(user: user)
    }

    private func listings(req: Request) async throws -> [ListingResponse] {
        guard let userID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        guard try await User.find(userID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "User not found.")
        }

        let listings = try await Listing.query(on: req.db)
            .filter(\.$seller.$id == userID)
            .with(\.$seller)
            .sort(\.$createdAt, .descending)
            .all()

        return try listings.map(ListingResponse.init)
    }
}
