import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct APIClient {
    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: String = "http://localhost:8080", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func createUser(_ body: CreateUserRequest) async throws -> UserResponse {
        try await post("/users", body: body)
    }

    func getUsers() async throws -> [UserResponse] {
        try await get("/users")
    }

    func getUser(id: UUID) async throws -> UserResponse {
        try await get("/users/\(id.uuidString)")
    }

    func getUserListings(userID: UUID) async throws -> [ListingResponse] {
        try await get("/users/\(userID.uuidString)/listings")
    }

    func createListing(_ body: CreateListingRequest) async throws -> ListingResponse {
        try await post("/listings", body: body)
    }

    func getListings(page: Int, category: String?, query: String?) async throws -> PagedListingResponse {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]

        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        return try await get("/listings", queryItems: queryItems)
    }

    func getListing(id: UUID) async throws -> ListingResponse {
        try await get("/listings/\(id.uuidString)")
    }

    func deleteListing(id: UUID) async throws {
        try await delete("/listings/\(id.uuidString)")
    }

    private func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let request = try makeRequest(path: path, method: "GET", queryItems: queryItems)
        let data = try await execute(request: request, expectedStatusCodes: 200...299)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var request = try makeRequest(path: path, method: "POST")
        request.httpBody = try encoder.encode(body)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data = try await execute(request: request, expectedStatusCodes: 200...299)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func delete(_ path: String) async throws {
        let request = try makeRequest(path: path, method: "DELETE")
        _ = try await execute(request: request, expectedStatusCodes: 200...299)
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.serverError("Invalid API base URL: \(baseURL)")
        }

        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path = normalizedPath
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.serverError("Invalid API URL for path: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func execute(request: URLRequest, expectedStatusCodes: ClosedRange<Int>) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.connectionFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid server response")
        }

        guard expectedStatusCodes.contains(httpResponse.statusCode) else {
            let parsedReason = (try? decoder.decode(ServerError.self, from: data).reason)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallback = defaultMessage(for: httpResponse.statusCode, path: request.url?.path ?? "")
            let message = (parsedReason?.isEmpty == false ? parsedReason! : fallback)

            switch httpResponse.statusCode {
            case 404:
                throw APIError.notFound(message)
            case 409:
                throw APIError.conflict(message)
            case 422:
                throw APIError.validationFailed(message)
            case 500...599:
                throw APIError.serverError(message)
            default:
                throw APIError.serverError(message)
            }
        }

        return data
    }

    private func defaultMessage(for statusCode: Int, path: String) -> String {
        switch statusCode {
        case 404:
            if path.contains("/listings") {
                return "Listing not found."
            }
            if path.contains("/users") {
                return "User not found."
            }
            return "Resource not found."
        case 409:
            if path == "/users" {
                return "A user with this username or email already exists."
            }
            return "Conflict."
        case 422:
            return "Validation failed."
        case 500...599:
            return "Server error."
        default:
            return "Request failed with status \(statusCode)."
        }
    }
}