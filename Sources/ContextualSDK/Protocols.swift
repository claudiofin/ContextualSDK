//
//  Protocols.swift
//  ContextualSDK
//
//  Additional protocols for customizing SDK behavior
//  NOTE: ContextualRendererProtocol and ContextualBrain are defined in Core.swift
//

import SwiftUI

// MARK: - Signature Provider Protocol

/// Protocol for providing custom signature capture implementations
public protocol SignatureProviderProtocol {
    associatedtype SignatureBody: View
    
    /// Binding to signature data
    var signatureData: Binding<Data?> { get }
    
    /// Build the signature capture view
    @ViewBuilder func body() -> SignatureBody
}

// MARK: - Custom Control Protocol

/// Protocol for registering custom native controls
public protocol CustomNativeControlProtocol {
    associatedtype ControlBody: View
    
    /// The control identifier (e.g., "myCustomSlider")
    static var identifier: String { get }
    
    /// Build the control view
    @ViewBuilder static func build(config: NativeConfig, value: Binding<String>) -> ControlBody
}

// MARK: - Brain Factory Protocol

/// Protocol for creating custom brain implementations at runtime
public protocol BrainFactoryProtocol {
    /// Create a brain instance
    func createBrain() -> any ContextualBrain
}

// MARK: - Style Configuration

/// Configuration for theming the renderer
public struct ContextualStyle: Sendable {
    public var backgroundColor: Color
    public var cornerRadius: CGFloat
    public var shadowRadius: CGFloat
    public var accentColor: Color
    public var labelFont: Font
    public var placeholderFont: Font
    
    public init(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 5,
        accentColor: Color = .blue,
        labelFont: Font = .headline,
        placeholderFont: Font = .body
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.accentColor = accentColor
        self.labelFont = labelFont
        self.placeholderFont = placeholderFont
    }
    
    /// Default style
    public static let `default` = ContextualStyle()
    
    /// Dark mode style
    public static let dark = ContextualStyle(
        backgroundColor: Color(white: 0.15),
        accentColor: .cyan
    )
}

// MARK: - Custom Renderer Builder

/// Builder for creating custom renderers with closures
public struct CustomRendererBuilder<Content: View> {
    private let decision: InputDecision
    private let value: Binding<String>
    private let content: (InputDecision, Binding<String>) -> Content
    
    public init(
        decision: InputDecision,
        value: Binding<String>,
        @ViewBuilder content: @escaping (InputDecision, Binding<String>) -> Content
    ) {
        self.decision = decision
        self.value = value
        self.content = content
    }
    
    public func build() -> Content {
        content(decision, value)
    }
}

// MARK: - View Extensions for Styling

public extension View {
    /// Apply contextual style to a view
    func styled(with style: ContextualStyle) -> some View {
        self
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .shadow(radius: style.shadowRadius)
    }
}
