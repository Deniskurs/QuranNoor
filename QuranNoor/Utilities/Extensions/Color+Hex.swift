//
//  Color+Hex.swift
//  QuraanNoor
//
//  Extension to create SwiftUI Color from hex string
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (e.g., "#FF5733" or "FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert Color to hex string
    /// - Parameter includeAlpha: Whether to include alpha channel in the hex string
    /// - Returns: Hex string representation (e.g., "#FF5733")
    func toHex(includeAlpha: Bool = false) -> String? {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        #elseif canImport(AppKit)
        guard let components = NSColor(self).cgColor.components else {
            return nil
        }
        #endif

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        let a = components.count >= 4 ? Int(components[3] * 255.0) : 255

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}
