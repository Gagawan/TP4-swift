import Foundation

enum APIError: Error {
    case notFound(String)
    case conflict(String)
    case validationFailed(String)
    case serverError(String)
    case connectionFailed
    case decodingError(Error)
}

extension APIError {
    var message: String {
        switch self {
        case .notFound(let reason):
            return "Error: \(fallback(reason, default: "Resource not found."))"
        case .conflict(let reason):
            return "Error: \(fallback(reason, default: "Conflict."))"
        case .validationFailed(let reason):
            let normalized = fallback(reason, default: "Validation failed.")
            if normalized.lowercased().hasPrefix("validation failed") {
                return "Error: \(normalized)"
            }
            return "Error: Validation failed.\n\(normalized)"
        case .serverError(let reason):
            return "Error: \(fallback(reason, default: "Server error."))"
        case .connectionFailed:
            return "Error: Could not connect to server at http://localhost:8080.\nMake sure the server is running: swift run in swiftmarket-server/"
        case .decodingError(let error):
            return "Error: Failed to decode server response (\(error.localizedDescription))."
        }
    }

    private func fallback(_ text: String?, default defaultText: String) -> String {
        guard let text else { return defaultText }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultText : trimmed
    }
}