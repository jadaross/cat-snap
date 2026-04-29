import SwiftUI

// PostScript names match the .ttf files bundled in Resources/Fonts/.
// Verify in Font Book if anything renders as system default: open the .ttf,
// look for "PostScript name". To add a new weight: drop the file in
// Resources/Fonts/, register it in Info.plist UIAppFonts, then add a case here.
extension Font {
    enum Brand {
        static func jakarta(_ weight: JakartaWeight, size: CGFloat) -> Font {
            .custom(weight.postScriptName, size: size)
        }

        // Only Fraunces variant currently bundled — used for the wordmark.
        // Add more Fraunces helpers if/when headline moments need them.
        static func frauncesBlackItalic(size: CGFloat) -> Font {
            .custom("Fraunces72pt-BlackItalic", size: size)
        }

        // Only JetBrains Mono Regular is bundled — for tiny system stamps.
        static func mono(size: CGFloat) -> Font {
            .custom("JetBrainsMono-Regular", size: size)
        }
    }

    enum JakartaWeight {
        case regular, medium, semibold, bold

        var postScriptName: String {
            switch self {
            case .regular:   return "PlusJakartaSans-Regular"
            case .medium:    return "PlusJakartaSans-Medium"
            case .semibold:  return "PlusJakartaSans-SemiBold"
            case .bold:      return "PlusJakartaSans-Bold"
            }
        }
    }
}
