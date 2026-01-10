//
//  RegexBrain.swift
//  ContextualIntelligence
//
//  Regex-based fallback analyzer. Works offline, no AI required.
//

import Foundation
import ContextualSDK
import OSLog

/// A rule-based analyzer that uses keyword matching to decide input strategy.
/// Use as a fallback when AI is unavailable.
public struct RegexBrain: ContextualBrain, Sendable {
    
    public init() {}
    
    public func decide(for context: FieldContext) async throws -> InputDecision {
        let name = context.name.lowercased()
        Logger.brain.debug("[RegexBrain] Analyzing field: '\(name)' (original: '\(context.name)')")
        
        let decision: InputDecision
        defer {
            Logger.brain.info("[RegexBrain] Decision: \(decision.strategy.rawValue) | Label: \(decision.label ?? "nil")")
        }

        // === SIGNATURE ===
        if name.contains("firma") || name.contains("signature") || name.contains("sign") {
            decision = InputDecision(strategy: .signature, label: "Signature", placeholder: "Draw here")
            return decision
        }
        
        // === DATE ===
        if name.contains("data") || name.contains("date") || name.contains("nascita") || name.contains("birth") {
            decision = InputDecision(
                strategy: .native,
                label: cleanLabel(context.name),
                placeholder: "Select date",
                native: NativeConfig(control: "datePicker")
            )
            return decision
        }
        
        // === COLOR ===
        if name.contains("colore") || name.contains("color") || name.contains("aura") {
            decision = InputDecision(
                strategy: .native,
                label: cleanLabel(context.name),
                placeholder: "Pick color",
                native: NativeConfig(control: "colorPicker")
            )
            return decision
        }
        
        // === WEBVIEW (Explicit via keywords) ===
        if name.contains("web") || name.contains("html") || name.contains("custom") || 
           name.contains("map") || name.contains("location") || name.contains("indirizzo") {
            decision = InputDecision(
                strategy: .webview,
                label: cleanLabel(context.name),
                webview: WebViewConfig(html: """
                    <div style="padding: 20px; text-align: center; color: white; font-family: -apple-system;">
                        <h3>🌍 WebView</h3>
                        <p>Showing custom HTML for <b>\(name)</b></p>
                        <button onclick="sendValue('Confirmed')" style="padding: 10px 20px; font-size: 16px; border-radius: 8px;">Confirm</button>
                    </div>
                """)
            )
            return decision
        }
        
        // === PICKER / SELECT / COUNTRY (WebView Demo) ===
        if name.contains("select") || name.contains("country") || name.contains("paese") || 
           name.contains("city") || name.contains("città") || name.contains("choose") ||
           name.contains("region") || name.contains("province") || name.contains("stato") {
            
            // Generate HTML for the webview
            let options = inferOptions(for: name)
            let optionsHtml = options.map { "<option value='\($0)'>\($0)</option>" }.joined()
            let html = """
                <div style="font-family: -apple-system, sans-serif; padding: 10px; color: white;">
                    <label style="font-size: 14px; color: #888;">Select Option</label>
                    <select onchange="sendValue(this.value)" style="
                        width: 100%;
                        font-size: 18px;
                        padding: 12px;
                        margin-top: 8px;
                        background: #1c1c1e;
                        color: white;
                        border: 1px solid #333;
                        border-radius: 8px;
                        -webkit-appearance: none;
                    ">
                        <option value="">Choose...</option>
                        \(optionsHtml)
                    </select>
                </div>
            """
            
            decision = InputDecision(
                strategy: .webview,
                label: cleanLabel(context.name),
                placeholder: "Select option",
                webview: WebViewConfig(html: html)
            )
            return decision
        }
        
        // === RATING / SLIDER ===
        if name.contains("rating") || name.contains("valut") || name.contains("stars") || 
           name.contains("stelle") || name.contains("score") || name.contains("level") {
            let range = inferRange(for: name)
            decision = InputDecision(
                strategy: .native,
                label: cleanLabel(context.name),
                placeholder: nil,
                native: NativeConfig(control: "slider", range: range)
            )
            return decision
        }
        
        // === TOGGLE ===
        if name.contains("[ ]") || name.contains("[x]") || name.contains("accept") || 
           name.contains("agree") || name.contains("consent") || name.contains("terms") {
            decision = InputDecision(
                strategy: .native,
                label: cleanLabel(context.name),
                native: NativeConfig(control: "toggle")
            )
            return decision
        }
        
        // === EMAIL ===
        if name.contains("email") || name.contains("e-mail") || name.contains("mail") {
            decision = InputDecision(
                strategy: .keyboard,
                label: cleanLabel(context.name),
                placeholder: "email@example.com",
                keyboard: KeyboardConfig(type: "email", contentType: "emailAddress", autocapitalization: "none")
            )
            return decision
        }
        
        // === PHONE ===
        if name.contains("phone") || name.contains("telefono") || name.contains("cell") || name.contains("mobile") {
            decision = InputDecision(
                strategy: .keyboard,
                label: cleanLabel(context.name),
                placeholder: "+1...",
                keyboard: KeyboardConfig(type: "phone", contentType: "telephoneNumber", autocapitalization: "none")
            )
            return decision
        }
        
        // === NUMBER / QUANTITY ===
        if name.contains("number") || name.contains("quantity") || name.contains("amount") ||
           name.contains("età") || name.contains("age") || name.contains("numero") {
            decision = InputDecision(
                strategy: .keyboard,
                label: cleanLabel(context.name),
                placeholder: "0",
                keyboard: KeyboardConfig(type: "number", autocapitalization: "none")
            )
            return decision
        }
        
        // === PASSWORD ===
        if name.contains("password") || name.contains("pwd") || name.contains("secret") {
            decision = InputDecision(
                strategy: .keyboard,
                label: cleanLabel(context.name),
                placeholder: "••••••••",
                keyboard: KeyboardConfig(type: "default", contentType: "password", autocapitalization: "none")
            )
            return decision
        }
        
        // === NAME ===
        if name.contains("name") || name.contains("nome") || name.contains("cognome") || name.contains("surname") {
            decision = InputDecision(
                strategy: .keyboard,
                label: cleanLabel(context.name),
                placeholder: "John Doe",
                keyboard: KeyboardConfig(type: "default", contentType: "name", autocapitalization: "words")
            )
            return decision
        }
        
        // === DEFAULT ===
        decision = InputDecision(
            strategy: .keyboard,
            label: cleanLabel(context.name),
            placeholder: "Enter value",
            keyboard: KeyboardConfig(type: "default", autocapitalization: "sentences")
        )
        return decision
    }
    
    private func cleanLabel(_ label: String) -> String {
        var cleaned = label
        if cleaned.hasSuffix(":") { cleaned = String(cleaned.dropLast()) }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    private func inferOptions(for name: String) -> [String] {
        if name.contains("country") || name.contains("paese") {
            return ["Italy", "USA", "UK", "France", "Germany", "Spain"]
        }
        if name.contains("city") || name.contains("città") {
            return ["Milan", "Rome", "Turin", "Naples", "Florence"]
        }
        return ["Option 1", "Option 2", "Option 3"]
    }
    
    private func inferRange(for name: String) -> [Double] {
        if name.contains("star") || name.contains("stell") {
            return [1, 5, 1]
        }
        return [0, 100, 1]
    }
}
