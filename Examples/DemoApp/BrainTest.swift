
import Foundation

// MARK: - Mocks
public struct FieldContext {
    public let name: String
    public let type: String
    public let nearbyText: String
    
    public init(name: String, type: String = "text", nearbyText: String = "") {
        self.name = name
        self.type = type
        self.nearbyText = nearbyText
    }
}

public enum InputStrategy: String {
    case keyboard
    case native
    case signature
    case webview
}

public struct InputDecision {
    public let strategy: InputStrategy
    public let label: String?
    public let webview: WebViewConfig?
    
    public init(strategy: InputStrategy, label: String? = nil, webview: WebViewConfig? = nil) {
        self.strategy = strategy
        self.label = label
        self.webview = webview
    }
}

public struct WebViewConfig {
    public let html: String
    public init(html: String) { self.html = html }
}

public struct NativeConfig {
    public let control: String
    public let range: [Double]?
    public init(control: String, range: [Double]? = nil) {
        self.control = control
        self.range = range
    }
}

public struct KeyboardConfig {
    public let type: String
}

// MARK: - RegexBrain Logic (Copied - MOCK)
public struct MockRegexBrain {
    public init() {}
    
    public func decide(for context: FieldContext) -> InputDecision {
        let name = context.name.lowercased()
        
        // === SIGNATURE ===
        if name.contains("firma") || name.contains("signature") || name.contains("sign") {
            return InputDecision(strategy: .signature, label: name)
        }
        
        // === DATE ===
        if name.contains("data") || name.contains("date") || name.contains("nascita") || name.contains("birth") {
            return InputDecision(strategy: .native, label: name)
        }
        
        // === COLOR ===
        if name.contains("colore") || name.contains("color") || name.contains("aura") {
            return InputDecision(strategy: .native, label: name)
        }
        
        // === WEBVIEW (Explicit via keywords) ===
        if name.contains("web") || name.contains("html") || name.contains("custom") || 
           name.contains("map") || name.contains("location") || name.contains("indirizzo") {
            let config = WebViewConfig(html: "mock")
            return InputDecision(strategy: .webview, label: name, webview: config)
        }
        
        // === PICKER / SELECT / COUNTRY (WebView Demo) ===
        if name.contains("select") || name.contains("country") || name.contains("paese") || 
           name.contains("city") || name.contains("città") || name.contains("choose") ||
           name.contains("region") || name.contains("province") || name.contains("stato") {
            let config = WebViewConfig(html: "mock")
            return InputDecision(strategy: .webview, label: name, webview: config)
        }
        
        return InputDecision(strategy: .keyboard, label: name)
    }
}

// MARK: - Test Runner
let testCases = [
    "webview input",
    "custom form",
    "google map",
    "user location",
    "show html",
    "indirizzo di casa", // italian address
    "date of birth", // Should be native
    "colore preferito", // Should be native
    "firma qui", // Should be signature
    "email address", // Should be keyboard (default fallback in this simplified version since I trimmed it)
    "select country" // Should be webview
]

print("--- Running RegexBrain Verification (MOCK) ---")
let brain = MockRegexBrain()

for test in testCases {
    let context = FieldContext(name: test)
    let decision = brain.decide(for: context)
    let status = decision.strategy == .webview ? "✅" : "❌"
    let expected = (test.contains("date") || test.contains("color") || test.contains("firma") || test.contains("email")) ? "native/sig/key" : "webview"
    
    // logic adjustment for display:
    // "email address" -> regex logic puts it as keyboard. That's fine.
    // "date" -> native.
    
    print("Input: '\(test)' -> Strategy: \(decision.strategy.rawValue)")
}
