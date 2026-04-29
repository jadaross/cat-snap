import Foundation
import UIKit
import Supabase
import Storage
import Auth

enum AvatarUpload {
    /// Compresses the image to a 512px JPEG, uploads to the `avatars` bucket
    /// at `<user_id>/<uuid>.jpg`, and updates `profiles.avatar_url`.
    /// Returns the new public URL.
    static func uploadAndSetAvatar(_ image: UIImage) async throws -> URL {
        let userId = try await supabase.auth.session.user.id

        guard let data = image.resizedJPEGData(maxEdge: 512, quality: 0.8) else {
            throw PhotoUpload.Error.compressionFailed
        }

        let path = "\(userId.uuidString.lowercased())/\(UUID().uuidString).jpg"
        let bucket = supabase.storage.from("avatars")

        try await bucket.upload(
            path,
            data: data,
            options: FileOptions(contentType: "image/jpeg", upsert: false)
        )

        let publicURL = try bucket.getPublicURL(path: path)

        struct AvatarUpdate: Encodable {
            let avatar_url: String
        }
        try await supabase
            .from("profiles")
            .update(AvatarUpdate(avatar_url: publicURL.absoluteString))
            .eq("id", value: userId)
            .execute()

        return publicURL
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
