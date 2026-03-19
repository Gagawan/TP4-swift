import Fluent
import Vapor

struct ListingController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let listings = routes.grouped("listings")

        listings.get(use: index)
        listings.post(use: create)

        listings.group(":id") { listing in
            listing.get(use: show)
            listing.delete(use: delete)
        }
    }

    private struct ListingListQuery: Content {
        var page: Int?
        var per: Int?
        var category: String?
        var q: String?
    }

    private func index(req: Request) async throws -> PagedListingResponse {
        let query = try req.query.decode(ListingListQuery.self)
        let page = max(1, query.page ?? 1)
        let per = min(max(1, query.per ?? 10), 20)

        let builder = Listing.query(on: req.db)
            .with(\.$seller)
            .sort(\.$createdAt, .descending)

        if let category = query.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            builder.filter(\.$category == category.lowercased())
        }

        let listings = try await builder.all()

        let filteredListings: [Listing]
        if let search = query.q?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            filteredListings = listings.filter {
                $0.title.localizedCaseInsensitiveContains(search)
                    || $0.description.localizedCaseInsensitiveContains(search)
            }
        } else {
            filteredListings = listings
        }

        let totalCount = filteredListings.count
        let totalPages = totalCount == 0 ? 0 : (totalCount + per - 1) / per
        let startIndex = (page - 1) * per
        let endIndex = min(startIndex + per, totalCount)

        let pagedItems: [Listing]
        if startIndex < totalCount {
            pagedItems = Array(filteredListings[startIndex..<endIndex])
        } else {
            pagedItems = []
        }

        let items = try pagedItems.map(ListingResponse.init)

        return PagedListingResponse(
            items: items,
            page: page,
            totalPages: totalPages,
            totalCount: totalCount
        )
    }

    private func create(req: Request) async throws -> Response {
        do {
            try CreateListingRequest.validate(content: req)
        } catch {
            if let payload = try? req.content.decode(CreateListingRequest.self) {
                var validationMessages: [String] = []
                if payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    validationMessages.append("title must not be empty")
                }
                if payload.price <= 0 {
                    validationMessages.append("price must be greater than 0")
                }
                if !validationMessages.isEmpty {
                    throw Abort(.unprocessableEntity, reason: validationMessages.joined(separator: ", "))
                }
            }

            throw Abort(.unprocessableEntity, reason: "Validation failed.\n\(error.localizedDescription)")
        }

        let payload = try req.content.decode(CreateListingRequest.self)

        var validationMessages: [String] = []
        if payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessages.append("title must not be empty")
        }
        if payload.price <= 0 {
            validationMessages.append("price must be greater than 0")
        }
        if !validationMessages.isEmpty {
            throw Abort(.unprocessableEntity, reason: validationMessages.joined(separator: ", "))
        }

        guard CreateListingRequest.allowedCategories.contains(payload.category.lowercased()) else {
            throw Abort(.unprocessableEntity, reason: "category must be one of: electronics, clothing, furniture, other")
        }

        guard let _ = try await User.find(payload.sellerID, on: req.db) else {
            throw Abort(.notFound, reason: "Seller not found")
        }

        let listing = Listing(
            title: payload.title,
            description: payload.description,
            price: payload.price,
            category: payload.category.lowercased(),
            sellerID: payload.sellerID
        )

        try await listing.save(on: req.db)
        try await listing.$seller.load(on: req.db)

        let response = try ListingResponse(listing: listing)
        return try await response.encodeResponse(status: .created, for: req)
    }

    private func show(req: Request) async throws -> ListingResponse {
        guard let listingID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.notFound, reason: "Listing not found.")
        }

        guard let listing = try await Listing.query(on: req.db)
            .filter(\.$id == listingID)
            .with(\.$seller)
            .first()
        else {
            throw Abort(.notFound, reason: "Listing not found.")
        }

        return try ListingResponse(listing: listing)
    }

    private func delete(req: Request) async throws -> HTTPStatus {
        guard let listingID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.notFound, reason: "Listing not found.")
        }

        guard let listing = try await Listing.find(listingID, on: req.db) else {
            throw Abort(.notFound, reason: "Listing not found.")
        }

        try await listing.delete(on: req.db)
        return .noContent
    }
}
