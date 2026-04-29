import Foundation
import ImageIO
import CoreLocation

// EXIF/GPS extraction from a photo's raw bytes. Lets us pre-fill the
// Submit form's date and location when the user uploads from their
// camera roll instead of capturing fresh — without ever requiring
// PhotoKit permission. Source: design's "Upload from photos" flow,
// `CatSnap App.html` lines 564–599 (CameraRollDetail).
enum ExifMetadata {
    struct Extracted {
        var creationDate: Date?
        var location: CLLocation?
    }

    static func extract(from data: Data) -> Extracted {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let raw = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return Extracted()
        }

        var result = Extracted()
        result.creationDate = parseDate(from: raw)
        result.location = parseLocation(from: raw)
        return result
    }

    private static func parseDate(from props: [CFString: Any]) -> Date? {
        guard let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] else {
            return nil
        }
        let candidates: [CFString] = [
            kCGImagePropertyExifDateTimeOriginal,
            kCGImagePropertyExifDateTimeDigitized
        ]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        for key in candidates {
            if let raw = exif[key] as? String, let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }

    private static func parseLocation(from props: [CFString: Any]) -> CLLocation? {
        guard let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }
        guard let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double else {
            return nil
        }
        let latRef = (gps[kCGImagePropertyGPSLatitudeRef] as? String) ?? "N"
        let lonRef = (gps[kCGImagePropertyGPSLongitudeRef] as? String) ?? "E"
        let signedLat = latRef.uppercased() == "S" ? -lat : lat
        let signedLon = lonRef.uppercased() == "W" ? -lon : lon
        return CLLocation(latitude: signedLat, longitude: signedLon)
    }
}
