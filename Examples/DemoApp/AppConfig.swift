//
//  AppConfig.swift
//  SampleApp
//
//  Configuration and environment detection
//

import Foundation
import ContextualSDK

enum AppConfig {
    
    /// Returns true if running in UI test mode
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }
    
    /// Returns true if running in unit test mode
    static var isTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    // MARK: - Mock Decisions for UI Testing
    
    static let mockOnboardingDecisions: [String: InputDecision] = [
        "firstName": InputDecision(strategy: .keyboard, label: "First Name", placeholder: "John"),
        "lastName": InputDecision(strategy: .keyboard, label: "Last Name", placeholder: "Doe"),
        "email": {
            var d = InputDecision(strategy: .keyboard, label: "Email", placeholder: "email@example.com")
            d.keyboard = KeyboardConfig(type: "email", contentType: "emailAddress", autocapitalization: "none")
            return d
        }(),
        "phone": {
            var d = InputDecision(strategy: .keyboard, label: "Phone", placeholder: "+1...")
            d.keyboard = KeyboardConfig(type: "phone", contentType: "telephoneNumber", autocapitalization: "none")
            return d
        }(),
        "birthDate": {
            var d = InputDecision(strategy: .native, label: "Date of Birth", placeholder: "Select date")
            d.native = NativeConfig(control: "datePicker")
            return d
        }(),
        "taxCode": InputDecision(strategy: .keyboard, label: "Tax Code", placeholder: "XXX-XX-XXXX"),
        "address": InputDecision(strategy: .keyboard, label: "Address", placeholder: "123 Main St"),
        "postalCode": InputDecision(strategy: .keyboard, label: "Postal Code", placeholder: "12345"),
        "province": InputDecision(strategy: .keyboard, label: "State", placeholder: "CA")
    ]
    
    static let mockPDFDecisions: [String: InputDecision] = [
        "currentDate": {
            var d = InputDecision(strategy: .native, label: "Date", placeholder: "Today")
            d.native = NativeConfig(control: "datePicker")
            return d
        }(),
        "amount": InputDecision(strategy: .keyboard, label: "Amount", placeholder: "$ 0.00"),
        "notes": InputDecision(strategy: .keyboard, label: "Notes", placeholder: "Enter notes..."),
        "acceptTerms": {
            var d = InputDecision(strategy: .native, label: "Accept")
            d.native = NativeConfig(control: "toggle")
            return d
        }(),
        "signature": InputDecision(strategy: .signature, label: "Signature", placeholder: "Draw here")
    ]
    
    static let mockSettingsDecisions: [String: InputDecision] = [
        "theme": InputDecision(strategy: .keyboard, label: "Theme", placeholder: "Light/Dark"),
        "volume": {
            var d = InputDecision(strategy: .native, label: "Volume")
            d.native = NativeConfig(control: "slider", range: [0, 100, 1], unit: "%")
            return d
        }(),
        "accentColor": {
            var d = InputDecision(strategy: .native, label: "Color")
            d.native = NativeConfig(control: "colorPicker")
            return d
        }(),
        "notifications": {
            var d = InputDecision(strategy: .native, label: "Notifications")
            d.native = NativeConfig(control: "toggle")
            return d
        }()
    ]
}
