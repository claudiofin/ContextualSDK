import XCTest
import SwiftUI
@testable import ContextualSDK
@testable import ContextualUI

/// UI Tests for ContextualRenderer using ViewInspector-style assertions
final class RendererUITests: XCTestCase {
    
    // MARK: - Keyboard Strategy Tests
    
    func testKeyboardRendererShowsTextField() throws {
        var decision = InputDecision(strategy: .keyboard, label: "Email", placeholder: "Enter email")
        decision.keyboard = KeyboardConfig(type: "email", contentType: "emailAddress", autocapitalization: "none")
        
        // Verify decision is valid
        XCTAssertEqual(decision.strategy, .keyboard)
        XCTAssertEqual(decision.label, "Email")
        XCTAssertEqual(decision.keyboard?.type, "email")
    }
    
    func testKeyboardRendererDefaultConfig() throws {
        let decision = InputDecision(strategy: .keyboard, label: "Name", placeholder: "Enter name")
        
        XCTAssertEqual(decision.strategy, .keyboard)
        XCTAssertNil(decision.keyboard) // No config means default
    }
    
    // MARK: - Native Strategy Tests
    
    func testDatePickerRendererShowsDatePicker() throws {
        var decision = InputDecision(strategy: .native, label: "Birth Date")
        decision.native = NativeConfig(control: "datePicker")
        
        XCTAssertEqual(decision.strategy, .native)
        XCTAssertEqual(decision.native?.control, "datePicker")
    }
    
    func testColorPickerRendererShowsColorPicker() throws {
        var decision = InputDecision(strategy: .native, label: "Favorite Color")
        decision.native = NativeConfig(control: "colorPicker")
        
        XCTAssertEqual(decision.strategy, .native)
        XCTAssertEqual(decision.native?.control, "colorPicker")
    }
    
    func testToggleRendererShowsToggle() throws {
        var decision = InputDecision(strategy: .native, label: "Accept Terms")
        decision.native = NativeConfig(control: "toggle")
        
        XCTAssertEqual(decision.strategy, .native)
        XCTAssertEqual(decision.native?.control, "toggle")
    }
    
    func testSliderRendererShowsSlider() throws {
        var decision = InputDecision(strategy: .native, label: "Volume")
        decision.native = NativeConfig(control: "slider", range: [0, 100, 1], unit: "%")
        
        XCTAssertEqual(decision.strategy, .native)
        XCTAssertEqual(decision.native?.control, "slider")
        XCTAssertEqual(decision.native?.range, [0, 100, 1])
        XCTAssertEqual(decision.native?.unit, "%")
    }
    
    // MARK: - Signature Strategy Tests
    
    func testSignatureRendererShowsSignatureArea() throws {
        let decision = InputDecision(strategy: .signature, label: "Signature", placeholder: "Draw here")
        
        XCTAssertEqual(decision.strategy, .signature)
        XCTAssertEqual(decision.label, "Signature")
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testInputDecisionEncodesAndDecodes() throws {
        var original = InputDecision(strategy: .native, label: "Date", placeholder: "Pick a date")
        original.native = NativeConfig(control: "datePicker")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(InputDecision.self, from: data)
        
        XCTAssertEqual(decoded.strategy, original.strategy)
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.native?.control, original.native?.control)
    }
    
    func testFieldContextEncodesAndDecodes() throws {
        let original = FieldContext(name: "Email", type: "text", nearbyText: "Enter your email", metadata: ["hint": "required"])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FieldContext.self, from: data)
        
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.nearbyText, original.nearbyText)
        XCTAssertEqual(decoded.metadata["hint"], "required")
    }
}
