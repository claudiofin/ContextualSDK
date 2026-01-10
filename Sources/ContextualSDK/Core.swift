//
//  ContextualSDK.swift
//  ContextualSDK
//
//  Core Definitions
//

import Foundation
import SwiftUI

// MARK: - 🧠 Intelligence Protocol

/// The brain of the operation. Any AI or Logic that wants to drive the UI must implement this.
public protocol ContextualBrain: Sendable {
    /// Analyzes a field context and decides how to render the input.
    /// - Parameter context: The context of the field (name, surrounding text, etc.)
    /// - Returns: An InputDecision describing the UI to show.
    func decide(for context: FieldContext) async throws -> InputDecision
}

// MARK: - 🎨 UI Protocol

/// Protocol for custom UI rendering.
public protocol ContextualRendererProtocol {
    associatedtype Content: View
    func view(for decision: InputDecision, binding: Binding<String>) -> Content
}

// MARK: - 📦 Models

public struct FieldContext: Sendable, Codable {
    public let id: UUID
    public let name: String
    public let type: String
    public let nearbyText: String
    public let metadata: [String: String]
    
    public init(id: UUID = UUID(), name: String, type: String, nearbyText: String = "", metadata: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.type = type
        self.nearbyText = nearbyText
        self.metadata = metadata
    }
}

public struct InputDecision: Codable, Sendable {
    public var strategy: InputStrategy
    public var label: String?
    public var placeholder: String?
    
    // Detailed configuration
    public var keyboard: KeyboardConfig?
    public var native: NativeConfig?
    public var webview: WebViewConfig?
    public var map: MapConfig?
    
    public init(
        strategy: InputStrategy,
        label: String? = nil,
        placeholder: String? = nil,
        keyboard: KeyboardConfig? = nil,
        native: NativeConfig? = nil,
        webview: WebViewConfig? = nil,
        map: MapConfig? = nil
    ) {
        self.strategy = strategy
        self.label = label
        self.placeholder = placeholder
        self.keyboard = keyboard
        self.native = native
        self.webview = webview
        self.map = map
    }
    
    // Compatibility initializer for older code/tests (fixes Undefined symbol)
    public init(
        strategy: InputStrategy,
        label: String? = nil,
        placeholder: String? = nil,
        keyboard: KeyboardConfig? = nil,
        native: NativeConfig? = nil,
        webview: WebViewConfig? = nil
    ) {
        self.init(
            strategy: strategy,
            label: label,
            placeholder: placeholder,
            keyboard: keyboard,
            native: native,
            webview: webview,
            map: nil
        )
    }
}

public enum InputStrategy: String, Codable, Sendable {
    case keyboard
    case native
    case signature
    case webview
    case map
}

// MARK: - Configurations

public struct KeyboardConfig: Codable, Sendable {
    public var type: String // "default", "email", "phone"
    public var contentType: String? // "givenName", "emailAddress"
    public var autocapitalization: String // "sentences", "none"
    
    public init(type: String = "default", contentType: String? = nil, autocapitalization: String = "sentences") {
        self.type = type
        self.contentType = contentType
        self.autocapitalization = autocapitalization
    }
}

public struct NativeConfig: Codable, Sendable {
    public var control: String // "datePicker", "slider", "picker"
    public var options: [String]?
    public var range: [Double]? // [min, max, step]
    public var unit: String?
    
    public init(control: String, options: [String]? = nil, range: [Double]? = nil, unit: String? = nil) {
        self.control = control
        self.options = options
        self.range = range
        self.unit = unit
    }
}

public struct WebViewConfig: Codable, Sendable {
    public var html: String
    public init(html: String) {
        self.html = html
    }
}

public struct MapConfig: Codable, Sendable {
    public var initialRegion: [Double]? // [lat, long, spanLat, spanLong]
    public var showUserLocation: Bool
    
    public init(initialRegion: [Double]? = nil, showUserLocation: Bool = true) {
        self.initialRegion = initialRegion
        self.showUserLocation = showUserLocation
    }
}

// MARK: - ⚠️ Errors

public enum ContextualError: Error, LocalizedError, Sendable {
    case aiNotAvailable
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .aiNotAvailable:
            return "Apple Intelligence is not available on this device"
        case .invalidResponse:
            return "Could not parse AI response"
        }
    }
}
