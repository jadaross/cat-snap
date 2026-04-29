import Foundation
import UIKit
import Supabase
import Storage
import Auth

enum PhotoUpload {
    enum Error: LocalizedError {
        case compressionFailed
        case notSignedIn

        var errorDescription: String? {
            switch self {
            case .compressionFailed: return "Couldn't process the photo."
            case .notSignedIn:       return "Please sign in to upload photos."
            }
        }
    }

    /// Compresses to JPEG (q=0.7, max 1600px on long edge), uploads to the
    /// `sighting-photos` bucket under `<user_id>/<uuid>.jpg`, returns the
    /// public URL of the uploaded object.
    static func uploadSightingPhoto(_ image: UIImage) async throws -> URL {
        let userId = try await supabase.auth.session.user.id

        guard let data = image.resizedJPEGData(maxEdge: 1600, quality: 0.7) else {
            throw Error.compressionFailed
        }

        let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString).jpg"
        let bucket = supabase.storage.from("sighting-photos")

        try await bucket.upload(
            path,
            data: data,
            options: FileOptions(contentType: "image/jpeg", upsert: false)
        )

        return try bucket.getPublicURL(path: path)
    }
}

private extension UIImage {
    func resizedJPEGData(maxEdge: CGFloat, quality: CGFloat) -> Data? {
        let longEdge = max(size.width, size.height)
        let scaleFactor = longEdge > maxEdge ? maxEdge / longEdge : 1
        let target = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
