//
//  ContextualInputModifier.swift
//  ContextualUI
//
//  ViewModifier for easy contextual input integration
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence

// MARK: - Contextual Input Modifier

/// A ViewModifier that analyzes a field and renders the appropriate input control
public struct ContextualInputModifier: ViewModifier {
    let fieldName: String
    @Binding var value: String
    let brain: any ContextualBrain
    
    @State private var decision: InputDecision?
    @State private var isAnalyzing = true
    @State private var error: String?
    
    public init(fieldName: String, value: Binding<String>, brain: any ContextualBrain = RegexBrain()) {
        self.fieldName = fieldName
        self._value = value
        self.brain = brain
    }
    
    public func body(content: Content) -> some View {
        Group {
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let decision = decision {
                ContextualRenderer(decision: decision, value: $value)
            } else if let error = error {
                VStack {
                    content
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else {
                content
            }
        }
        .task {
            await analyze()
        }
    }
    
    private func analyze() async {
        let context = FieldContext(name: fieldName, type: "text")
        
        do {
            decision = try await brain.decide(for: context)
        } catch {
            self.error = error.localizedDescription
        }
        
        isAnalyzing = false
    }
}

// MARK: - Generative Input Modifier

/// A ViewModifier that uses AI to generate the best input control based on a prompt
public struct GenerativeInputModifier: ViewModifier {
    let prompt: String
    @Binding var value: String
    let brain: any ContextualBrain
    
    @State private var decision: InputDecision?
    @State private var isAnalyzing = true
    
    public init(prompt: String, value: Binding<String>, brain: any ContextualBrain = RegexBrain()) {
        self.prompt = prompt
        self._value = value
        self.brain = brain
    }
    
    public func body(content: Content) -> some View {
        Group {
            if isAnalyzing {
                HStack {
                    ProgressView()
                    Text("Generating UI...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let decision = decision {
                ContextualRenderer(decision: decision, value: $value)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                content
            }
        }
        .task {
            await generateInput()
        }
    }
    
    private func generateInput() async {
        let context = FieldContext(
            name: prompt,
            type: "generative",
            nearbyText: "Developer requested input for: \(prompt)"
        )
        
        do {
            decision = try await brain.decide(for: context)
        } catch {
            print("Generative Error: \(error)")
        }
        
        isAnalyzing = false
    }
}

// MARK: - View Extensions

public extension View {
    /// Applies contextual input analysis to a view
    func contextualInput(
        fieldName: String,
        value: Binding<String>,
        brain: any ContextualBrain = RegexBrain()
    ) -> some View {
        self.modifier(ContextualInputModifier(fieldName: fieldName, value: value, brain: brain))
    }
    
    /// Applies generative AI input to a view based on a prompt
    func generativeInput(
        prompt: String,
        value: Binding<String>,
        brain: any ContextualBrain = RegexBrain()
    ) -> some View {
        self.modifier(GenerativeInputModifier(prompt: prompt, value: value, brain: brain))
    }
}
