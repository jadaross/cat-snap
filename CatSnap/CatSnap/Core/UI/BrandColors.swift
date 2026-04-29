import SwiftUI

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    // Surfaces
    static let cream                = Color(hex: 0xF7F4EE)
    static let creamSoft            = Color(hex: 0xFFFBF2)
    static let creamDeep            = Color(hex: 0xEBE4D6)

    // Type
    static let ink                  = Color(hex: 0x252220)
    static let stone                = Color(hex: 0x807A72)
    static let stoneLight           = Color(hex: 0xE7E1D6)

    // Brand
    static let coral                = Color(hex: 0xFF6B5B)
    static let coralDeep            = Color(hex: 0xD44A3A)

    // Highlight (use sparingly — never on the wordmark, never as a large surface)
    static let streetlampYellow     = Color(hex: 0xFCD34D)
    static let streetlampYellowDeep = Color(hex: 0xF59E0B)
    static let sage                 = Color(hex: 0x7A9B7E)

    enum Rarity {
        // Source: catsnap-data.jsx RARITY constant
        static let commonForeground     = Color(hex: 0xA8A29E)
        static let commonBackground     = Color(hex: 0xF5F5F4)
        static let uncommonForeground   = Color(hex: 0x16A34A)
        static let uncommonBackground   = Color(hex: 0xDCFCE7)
        static let rareForeground       = Color(hex: 0x2563EB)
        static let rareBackground       = Color(hex: 0xDBEAFE)
        static let legendaryForeground  = Color(hex: 0xD97706)
        static let legendaryBackground  = Color(hex: 0xFEF3C7)
    }
}
