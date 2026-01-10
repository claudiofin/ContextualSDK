//
//  InputOutput.swift
//  ContextualSDK
//
//  Unified output types for all input controls
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Input Output

/// Unified enum representing all possible output types from input controls
public enum InputOutput: Sendable {
    case text(String)
    case number(Double)
    case date(Date)
    case dates([Date])
    case color(ColorOutput)
    case signature(SignatureOutput)
    case toggle(Bool)
    case selection(String)
    
    /// Converts any output to a string representation
    public var stringValue: String {
        switch self {
        case .text(let s): return s
        case .number(let n): return String(format: "%.2f", n)
        case .date(let d): 
            let f = DateFormatter()
            f.dateFormat = "dd/MM/yyyy"
            return f.string(from: d)
        case .dates(let ds):
            let f = DateFormatter()
            f.dateFormat = "dd/MM"
            return ds.map { f.string(from: $0) }.joined(separator: ", ")
        case .color(let c): return c.hex
        case .signature(let s): return s.description
        case .toggle(let b): return b ? "[X]" : "[ ]"
        case .selection(let s): return s
        }
    }
}

// MARK: - Color Output

public struct ColorOutput: Sendable, Equatable {
    public let color: Color
    public let name: String
    public let hex: String
    
    public static func == (lhs: ColorOutput, rhs: ColorOutput) -> Bool {
        lhs.hex == rhs.hex
    }
    
    public init(color: Color) {
        self.color = color
        self.name = Self.colorName(for: color)
        self.hex = Self.colorHex(for: color)
    }
    
    public init(hex: String) {
        self.hex = hex
        self.color = Self.colorFromHex(hex)
        self.name = hex
    }
    
    private static func colorName(for color: Color) -> String {
        if color == .red { return "Red" }
        if color == .orange { return "Orange" }
        if color == .yellow { return "Yellow" }
        if color == .green { return "Green" }
        if color == .blue { return "Blue" }
        if color == .purple { return "Purple" }
        if color == .pink { return "Pink" }
        if color == .mint { return "Mint" }
        if color == .cyan { return "Cyan" }
        if color == .indigo { return "Indigo" }
        if color == .brown { return "Brown" }
        if color == .gray { return "Gray" }
        return colorHex(for: color)
    }
    
    private static func colorHex(for color: Color) -> String {
        #if canImport(UIKit)
        guard let components = UIColor(color).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return "#000000"
        #endif
    }
    
    private static func colorFromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}

// MARK: - Signature Output

public struct SignatureOutput: Sendable {
    #if canImport(UIKit)
    public let imageData: Data?
    
    public init(image: UIImage?) {
        self.imageData = image?.pngData()
    }
    
    public init(data: Data?) {
        self.imageData = data
    }
    
    public var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    #else
    public let imageData: Data?
    
    public init(data: Data?) {
        self.imageData = data
    }
    #endif
    
    public var isEmpty: Bool {
        imageData == nil || imageData?.isEmpty == true
    }
    
    public var description: String {
        if let data = imageData, !data.isEmpty {
            return "[Signature: \(data.count) bytes]"
        }
        return "[No signature]"
    }
    
    public var base64: String? {
        imageData?.base64EncodedString()
    }
}
