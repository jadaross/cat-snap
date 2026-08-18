import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case serverError
    case authenticationRequired
    case unauthorized
    case notFound
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection"
        case .serverError:
            return "Something went wrong. Please try again."
        case .authenticationRequired:
            return "Please sign in again"
        case .unauthorized:
            return "You don't have permission to do this"
        case .notFound:
            return "The requested item wasn't found"
        case .custom(let message):
            return message
        }
    }
    
    static func map(_ error: Error) -> AppError {
        // Check for common network errors
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("network") || 
           errorDescription.contains("connection") || 
           errorDescription.contains("offline") {
            return .networkUnavailable
        }
        
        if errorDescription.contains("unauthorized") || 
           errorDescription.contains("401") {
            return .authenticationRequired
        }
        
        if errorDescription.contains("404") || 
           errorDescription.contains("not found") {
            return .notFound
        }
        
        if errorDescription.contains("403") || 
           errorDescription.contains("forbidden") {
            return .unauthorized
        }
        
        if errorDescription.contains("500") || 
           errorDescription.contains("server") {
            return .serverError
        }
        
        // Default to server error for unknown errors
        return .serverError
    }
}