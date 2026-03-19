import Foundation

func printError(_ message: String) {
    fputs("\(message)\n", stderr)
}

func separator(_ width: Int = 65) -> String {
    String(repeating: "─", count: width)
}

func pad(_ value: String, to width: Int) -> String {
    if value.count >= width {
        return String(value.prefix(width))
    }
    return value + String(repeating: " ", count: width - value.count)
}

func formatPrice(_ value: Double) -> String {
    String(format: "%.2f€", value)
}

func formatDate(_ date: Date?) -> String {
    guard let date else { return "Unknown" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func nonEmptyOrFallback(_ input: String?, fallback: String) -> String {
    guard let input else { return fallback }
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? fallback : trimmed
}

func printListingRows(_ listings: [ListingResponse], includeSeller: Bool) {
    if includeSeller {
        print("\(pad("ID", to: 36))  \(pad("Title", to: 18)) \(pad("Price", to: 9)) \(pad("Category", to: 12)) Seller")
        for listing in listings {
            print("\(pad(listing.id.uuidString, to: 36))  \(pad(listing.title, to: 18)) \(pad(formatPrice(listing.price), to: 9)) \(pad(listing.category, to: 12)) \(listing.seller.username)")
        }
        return
    }

    print("\(pad("ID", to: 36))  \(pad("Title", to: 18)) \(pad("Price", to: 9)) Category")
    for listing in listings {
        print("\(pad(listing.id.uuidString, to: 36))  \(pad(listing.title, to: 18)) \(pad(formatPrice(listing.price), to: 9)) \(listing.category)")
    }
}

func handleAPIError(_ error: Error) {
    if let apiErr = error as? APIError {
        printError(apiErr.message)
    } else {
        printError(error.localizedDescription)
    }
}