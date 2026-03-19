import ArgumentParser
import Foundation

struct ListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listings",
        abstract: "List all listings"
    )

    @Option(help: "Page number")
    var page: Int = 1

    @Option(help: "Category filter")
    var category: String?

    @Option(name: .shortAndLong, help: "Search query")
    var query: String?

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            let response = try await api.getListings(page: page, category: category, query: query)
            if response.items.isEmpty {
                print("No listings found.")
                return
            }

            let hasFilters = (category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                || (query?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)

            if hasFilters {
                print("Listings (\(response.totalCount) results)")
            } else {
                let totalPages = max(response.totalPages, 1)
                print("Listings (page \(response.page)/\(totalPages) — \(response.totalCount) results)")
            }

            print(separator())
            printListingRows(response.items, includeSeller: true)

            if !hasFilters, response.totalPages > response.page {
                print(separator())
                print("Next page: swiftmarket listings --page \(response.page + 1)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct ListingCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listing",
        abstract: "Show a listing"
    )

    @Argument(help: "Listing ID")
    var id: String

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            guard let listingID = UUID(uuidString: id) else {
                throw APIError.validationFailed("Invalid listing ID format: \(id)")
            }

            let listing = try await api.getListing(id: listingID)
            print(listing.title)
            print(separator(41))
            print("Price:       \(formatPrice(listing.price))")
            print("Category:    \(listing.category)")
            print("Description: \(listing.description)")
            print("Seller:      \(listing.seller.username) (\(listing.seller.email))")
            print("Posted:      \(formatDate(listing.createdAt))")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct PostCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "post",
        abstract: "Create a listing"
    )

    @Option(help: "Listing title")
    var title: String

    @Option(name: .long, help: "Listing description")
    var desc: String

    @Option(help: "Listing price")
    var price: Double

    @Option(help: "Listing category")
    var category: String

    @Option(name: .long, help: "Seller user ID")
    var seller: String

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            guard let sellerUUID = UUID(uuidString: seller) else {
                throw APIError.validationFailed("Invalid seller ID format: \(seller)")
            }

            let body = CreateListingRequest(
                title: title,
                description: desc,
                price: price,
                category: category,
                sellerID: sellerUUID
            )
            let listing = try await api.createListing(body)
            print("Listing created successfully.")
            print("ID:          \(listing.id)")
            print("Title:       \(listing.title)")
            print("Price:       \(formatPrice(listing.price))")
            print("Category:    \(listing.category)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a listing"
    )

    @Argument(help: "Listing ID")
    var id: String

    private var api: APIClient { APIClient() }

    mutating func run() async throws {
        do {
            guard let listingID = UUID(uuidString: id) else {
                throw APIError.validationFailed("Invalid listing ID format: \(id)")
            }

            let listing = try await api.getListing(id: listingID)
            try await api.deleteListing(id: listingID)
            print("Listing \"\(listing.title)\" deleted.")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}