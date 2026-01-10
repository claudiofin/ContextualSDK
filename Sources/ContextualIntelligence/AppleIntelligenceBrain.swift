//
//  AppleIntelligenceBrain.swift
//  ContextualIntelligence
//
//  Uses FoundationModels (Apple Intelligence) to allow LLM-driven field analysis.
//

import Foundation
import ContextualSDK
import FoundationModels
import OSLog


@available(iOS 26.0, macOS 26.0, *)
public struct AppleIntelligenceBrain: ContextualBrain, Sendable {
    
    // MARK: - Brain Implementation
    
    public init(instructions: String? = nil) {
        // We allow custom instructions but fallback to default if nil
    }
    
    private var instructions: String {
        """
        You are an expert UI engineer. Analyze the input field and return a JSON configuration.
        
        STRATEGIES (Choose the BEST fit):

        1. "keyboard": For standard text input. 
           Config: { "type": "default"|"email"|"phone", "contentType": "givenName"|"emailAddress" }

        2. "native": PREFERRED for specific controls. 
           PRIORITY: If a native control fits, USE IT. Do NOT use webview.
           - Date/Time: { "control": "datePicker" }
           - Selection: { "control": "picker", "options": ["A", "B"] }
           - Toggle/Boolean: { "control": "toggle" }
           - Rating/Star: { "control": "slider", "range": [1, 5, 1], "unit": "stars" } 
             (e.g., "Rate 1-5", "How many stars") -> ALWAYS use "slider".

        3. "map": MANDATORY for Address, Location, or Geo-coordinates.
           - "Where do you live?", "Select delivery address", "City"
           Config: { "showUserLocation": true }

        4. "signature": Only for physical signature requests.

        5. "webview": LAST RESORT.
           - Use ONLY for complex Visual HTML layouts that generic native controls cannot handle.
           - Do NOT use for simple forms, ratings, or selections.
           Config: { "html": "<div...>Content</div>" }
        
        JSON SCHEMA (Strict nesting required):
        {
          "strategy": "native",
          "native": { "control": "slider", ... } // MUST be nested inside "native"
        }
        
        Example:
        { "strategy": "native", "native": { "control": "datePicker" } }
        
        Full Schema:
        {
          "strategy": "keyboard" | "native" | "map" | "signature" | "webview",
          "label": "Display Label",
          "placeholder": "Placeholder",
          "keyboard": { ... },
          "native": { ... },
          "map": { ... },
          "webview": { ... }
        }
        
        Return ONLY valid JSON.
        """
    }
    
    public func decide(for context: FieldContext) async throws -> InputDecision {
        // 1. Check availability FIRST
        let model = SystemLanguageModel.default
        let isAvailable = await model.availability
        
        var ready = false
        switch isAvailable {
        case .available: ready = true
        default: ready = false
        }
        
        guard ready else {
            Logger.brain.error("[AppleIntelligence] Model not available: \(String(describing: isAvailable))")
            throw ContextualError.aiNotAvailable
        }
        
        // 2. Prepare Prompt
        let prompt = """
        ANALYZING FIELD:
        Name: "\(context.name)"
        Type: \(context.type)
        Context: "\(context.nearbyText)"
        
        Return ONLY valid JSON, no markdown, no explanation.
        """
        
        // 3. Inference
        Logger.brain.info("[AppleIntelligence] Sending prompt for field: \(context.name)")
        
        // Use closure syntax for initialization as per Apple examples
        let instructionsText = self.instructions
        let session = LanguageModelSession {
            instructionsText
        }
        
        do {
            let response = try await session.respond(to: prompt)
            
            // 4. Parse
            // We access the content directly. The response is expected to be a Response<String> (or similar)
            // which has a `content` property containing the actual generated text.
            let responseText = response.content
            Logger.brain.debug("[AppleIntelligence] Raw Response: \(responseText)")
            
            let finalDecision = try parseResponse(responseText, fieldName: context.name)
            Logger.brain.info("[AppleIntelligence] Parsed Decision: \(finalDecision.strategy.rawValue)")
            return finalDecision
        } catch {
            Logger.brain.error("[AppleIntelligence] Session Error: \(error.localizedDescription)")
            // Fallback to keyboard on error (e.g. guardrail violation) instead of failing
            Logger.brain.notice("[AppleIntelligence] Error encountered, using safe fallback.")
            return createFallbackDecision(fieldName: context.name)
        }
    }
    
    private func parseResponse(_ text: String, fieldName: String) throws -> InputDecision {
        var jsonString = text
        
        // 1. Attempt to find JSON inside markdown code blocks ```json ... ```
        // We look for ```json ... ``` or just ``` ... ```
        let pattern = "```(?:json)?\\s*([\\s\\S]*?)\\s*```"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            jsonString = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            Logger.brain.debug("[AppleIntelligence] Extracted JSON from markdown block")
        } 
        // 2. Fallback: Find the last valid looking JSON object if no markdown block
        else if let start = text.range(of: "{"), let end = text.range(of: "}", options: .backwards) {
            let candidate = String(text[start.lowerBound...end.upperBound])
            if !candidate.contains("JSON SCHEMA") {
                jsonString = candidate
                Logger.brain.debug("[AppleIntelligence] Extracted JSON from brace matching")
            }
        }
        
        // Clean up any remaining markdown artifacts just in case
        jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        
        // Remove potentially leading/trailing literal newlines/backslashes
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("\\") { jsonString.removeFirst() }
        
        // 3. Decode
        if let data = jsonString.data(using: .utf8) {
            do {
                let decision = try JSONDecoder().decode(InputDecision.self, from: data)
                return decision
            } catch {
                Logger.brain.error("[AppleIntelligence] Decoding Error: \(error.localizedDescription)")
                Logger.brain.debug("[AppleIntelligence] Attempted to decode: \(jsonString)")
            }
        }
        
        // Fallback: return sensible default based on field analysis
        Logger.brain.warning("[AppleIntelligence] JSON parsing failed, using fallback.")
        return createFallbackDecision(fieldName: fieldName)
    }
    
    private func createFallbackDecision(fieldName: String) -> InputDecision {
        return InputDecision(strategy: .keyboard, label: fieldName, placeholder: "Enter \(fieldName)")
    }
}


