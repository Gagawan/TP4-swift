import ArgumentParser
import Foundation

struct CreateUserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-user",
        abstract: "Create a new user"
    )

    @Option(help: "Username")
    var username: String

    @Option(help: "Email")
    var email: String

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            let result = try await api.createUser(CreateUserRequest(username: username, email: email))
            print("User created successfully.")
            print("ID:       \(result.id)")
            print("Username: \(result.username)")
            print("Email:    \(result.email)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UsersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "users",
        abstract: "List users"
    )

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            let users = try await api.getUsers()
            if users.isEmpty {
                print("No users found.")
                return
            }

            print("Users (\(users.count))")
            print(separator())
            print("\(pad("ID", to: 36))  \(pad("Username", to: 10)) Email")
            for user in users {
                print("\(pad(user.id.uuidString, to: 36))  \(pad(user.username, to: 10)) \(user.email)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user",
        abstract: "Show a user"
    )

    @Argument(help: "User ID")
    var id: String

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            guard let userID = UUID(uuidString: id) else {
                throw APIError.validationFailed("Invalid user ID format: \(id)")
            }
            let user = try await api.getUser(id: userID)
            print(user.username)
            print("Email:        \(user.email)")
            print("Member since: \(formatDate(user.createdAt))")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UserListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user-listings",
        abstract: "List listings for a specific user"
    )

    @Argument(help: "User ID")
    var userID: String

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            guard let parsedUserID = UUID(uuidString: userID) else {
                throw APIError.validationFailed("Invalid user ID format: \(userID)")
            }

            let user = try await api.getUser(id: parsedUserID)
            let listings = try await api.getUserListings(userID: parsedUserID)
            if listings.isEmpty {
                print("No listings found for user \(parsedUserID).")
                return
            }

            print("Listings by \(user.username) (\(listings.count))")
            print(separator())
            printListingRows(listings, includeSeller: false)
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}