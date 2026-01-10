//
//  PowerShowcaseView.swift
//  SampleApp
//
//  Comprehensive demo showing the full power of ContextualSDK
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence
import ContextualUI

struct PowerShowcaseView: View {
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Section 1: Zero-Code Form
                Section {
                    NavigationLink {
                        ZeroCodeFormDemo()
                    } label: {
                        DemoRow(
                            icon: "wand.and.stars",
                            color: .purple,
                            title: "Zero-Code Form",
                            subtitle: "Just prompts → SDK generates inputs"
                        )
                    }
                } header: {
                    Text("Magic Generation")
                }
                
                // MARK: - Section 2: PDF-Style Detection
                Section {
                    NavigationLink {
                        PDFStyleDetectionDemo()
                    } label: {
                        DemoRow(
                            icon: "doc.viewfinder",
                            color: .blue,
                            title: "PDF Field Detection",
                            subtitle: "Simulated automatic field detection"
                        )
                    }
                } header: {
                    Text("Smart Detection")
                }
                
                // MARK: - Section 3: ViewModifier Power
                Section {
                    NavigationLink {
                        ViewModifierDemo()
                    } label: {
                        DemoRow(
                            icon: "arrow.triangle.swap",
                            color: .orange,
                            title: "ViewModifier Magic",
                            subtitle: "Transform any view into smart input"
                        )
                    }
                } header: {
                    Text("Developer Experience")
                }
                
                // MARK: - Section 4: Multi-Brain Comparison
                Section {
                    NavigationLink {
                        MultiBrainDemo()
                    } label: {
                        DemoRow(
                            icon: "brain.head.profile",
                            color: .pink,
                            title: "Multi-Brain Analysis",
                            subtitle: "Compare Regex vs AI results"
                        )
                    }
                } header: {
                    Text("Intelligence")
                }
            }
            .navigationTitle("SDK Showcase")
        }
    }
}

// MARK: - Demo Row

struct DemoRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Demo 1: Zero-Code Form

struct ZeroCodeFormDemo: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var birthDate = ""
    @State private var rating = ""
    @State private var notes = ""
    
    var body: some View {
        Form {
            Section {
                Text("You only write prompts. The SDK decides what input control to show.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Personal") {
                Text("Name field")
                    .generativeInput(prompt: "Full name of person", value: $name)
                
                Text("Email field")
                    .generativeInput(prompt: "Email address", value: $email)
                
                Text("Phone field")
                    .generativeInput(prompt: "Phone number", value: $phone)
            }
            
            Section("Additional") {
                Text("Date field")
                    .generativeInput(prompt: "Date of birth", value: $birthDate)
                
                Text("Rating field")
                    .generativeInput(prompt: "Rating from 1 to 5 stars", value: $rating)
            }
            
            Section("Values") {
                LabeledContent("Name", value: name.isEmpty ? "-" : name)
                LabeledContent("Email", value: email.isEmpty ? "-" : email)
                LabeledContent("Phone", value: phone.isEmpty ? "-" : phone)
                LabeledContent("Birth Date", value: birthDate.isEmpty ? "-" : birthDate)
                LabeledContent("Rating", value: rating.isEmpty ? "-" : rating)
            }
        }
        .navigationTitle("Zero-Code Form")
    }
}

// MARK: - Demo 2: PDF-Style Detection

struct PDFStyleDetectionDemo: View {
    @State private var fields: [DetectedFieldDemo] = [
        .init(name: "Nome:", type: "text"),
        .init(name: "Cognome:", type: "text"),
        .init(name: "Email:", type: "text"),
        .init(name: "Telefono:", type: "text"),
        .init(name: "Data di nascita:", type: "text"),
        .init(name: "Firma:", type: "signature"),
        .init(name: "Colore preferito:", type: "text"),
    ]
    @State private var decisions: [UUID: InputDecision] = [:]
    @State private var values: [UUID: String] = [:]
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(fields.count) fields detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    Task { await analyzeAll() }
                } label: {
                    Label(isAnalyzing ? "Analyzing..." : "Analyze All", systemImage: "bolt.fill")
                }
                .disabled(isAnalyzing)
            }
            .padding()
            .background(.bar)
            
            // Form
            List(fields) { field in
                VStack(alignment: .leading, spacing: 8) {
                    Text(field.name)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    if let decision = decisions[field.id] {
                        ContextualRenderer(
                            decision: decision,
                            value: binding(for: field.id)
                        )
                    } else {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Not analyzed yet")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .navigationTitle("PDF Detection")
    }
    
    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: { values[id] ?? "" },
            set: { values[id] = $0 }
        )
    }
    
    private func analyzeAll() async {
        isAnalyzing = true
        let brain = RegexBrain()
        
        for field in fields {
            let context = FieldContext(name: field.name, type: field.type)
            if let decision = try? await brain.decide(for: context) {
                await MainActor.run {
                    decisions[field.id] = decision
                }
            }
        }
        
        await MainActor.run { isAnalyzing = false }
    }
}

struct DetectedFieldDemo: Identifiable {
    let id = UUID()
    let name: String
    let type: String
}

// MARK: - Demo 3: ViewModifier Magic

struct ViewModifierDemo: View {
    @State private var traditionalValue = ""
    @State private var contextualValue = ""
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Traditional Approach")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    Code("""
TextField("Email", text: $email)
    .keyboardType(.emailAddress)
    .textContentType(.emailAddress)
    .autocapitalization(.none)
""")
                    
                    TextField("Enter email", text: $traditionalValue)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
            } header: {
                Label("Before", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ContextualSDK Approach")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    Code("""
Text("Email field")
    .contextualInput(
        fieldName: "Email address",
        value: $email
    )
""")
                    
                    Text("Email field")
                        .contextualInput(fieldName: "Email address", value: $contextualValue)
                }
            } header: {
                Label("After", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text("Benefits")
                            .font(.headline)
                    }
                    
                    BenefitRow(icon: "brain", text: "AI decides keyboard type automatically")
                    BenefitRow(icon: "keyboard", text: "Correct content type set")
                    BenefitRow(icon: "textformat", text: "Autocapitalization configured")
                    BenefitRow(icon: "checkmark.seal", text: "Accessibility hints included")
                }
            }
            
            Section("Values") {
                LabeledContent("Traditional", value: traditionalValue.isEmpty ? "-" : traditionalValue)
                LabeledContent("Contextual", value: contextualValue.isEmpty ? "-" : contextualValue)
            }
        }
        .navigationTitle("ViewModifier Magic")
    }
}

struct Code: View {
    let code: String
    
    init(_ code: String) {
        self.code = code
    }
    
    var body: some View {
        Text(code)
            .font(.caption.monospaced())
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Demo 4: Multi-Brain Comparison

struct MultiBrainDemo: View {
    @State private var fieldName = "Email address"
    @State private var regexResult: InputDecision?
    @State private var aiResult: InputDecision?
    @State private var regexTime: Double = 0
    @State private var aiTime: Double = 0
    @State private var isAnalyzing = false
    
    let sampleFields = [
        "Email address",
        "Date of birth",
        "Phone number",
        "Full name",
        "Signature",
        "Password",
        "Rating from 1 to 5",
        "Select your country"
    ]
    
    var body: some View {
        Form {
            Section("Select Field") {
                Picker("Field", selection: $fieldName) {
                    ForEach(sampleFields, id: \.self) { field in
                        Text(field).tag(field)
                    }
                }
                .pickerStyle(.menu)
                
                Button {
                    Task { await analyze() }
                } label: {
                    Label(isAnalyzing ? "Analyzing..." : "Compare Brains", systemImage: "play.fill")
                }
                .disabled(isAnalyzing)
            }
            
            Section("RegexBrain") {
                if let result = regexResult {
                    ShowcaseResultCard(decision: result, time: regexTime, color: .blue)
                } else {
                    Text("Not analyzed")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("AppleIntelligence") {
                if #available(iOS 26.0, *) {
                    if let result = aiResult {
                        ShowcaseResultCard(decision: result, time: aiTime, color: .purple)
                    } else {
                        Text("Not analyzed (tap Compare)")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label("Requires iOS 26+", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Multi-Brain")
    }
    
    private func analyze() async {
        await MainActor.run { isAnalyzing = true }
        
        let context = FieldContext(name: fieldName, type: "text")
        
        // Regex Brain
        let regexStart = Date()
        let regexBrain = RegexBrain()
        // Run brain off-main actor, then update UI
        if let result = try? await regexBrain.decide(for: context) {
            let duration = Date().timeIntervalSince(regexStart) * 1000
            await MainActor.run {
                regexResult = result
                regexTime = duration
            }
        }
        
        // Apple Intelligence
        if #available(iOS 26.0, *) {
            let aiStart = Date()
            let aiBrain = AppleIntelligenceBrain()
            if let result = try? await aiBrain.decide(for: context) {
                let duration = Date().timeIntervalSince(aiStart) * 1000
                await MainActor.run {
                    aiResult = result
                    aiTime = duration
                }
            }
        }
        
        await MainActor.run { isAnalyzing = false }
    }
}

struct ShowcaseResultCard: View {
    let decision: InputDecision
    let time: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(decision.strategy.rawValue.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(String(format: "%.1fms", time))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            if let label = decision.label {
                LabeledContent("Label", value: label)
                    .font(.caption)
            }
            
            if let placeholder = decision.placeholder {
                LabeledContent("Placeholder", value: placeholder)
                    .font(.caption)
            }
            
            if let keyboard = decision.keyboard {
                LabeledContent("Keyboard", value: keyboard.type)
                    .font(.caption)
            }
            
            if let native = decision.native {
                LabeledContent("Control", value: native.control)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    PowerShowcaseView()
}
