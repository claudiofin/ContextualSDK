//
//  DebugView.swift
//  SampleApp
//
//  Debug view with brain selector and analysis log
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence
import ContextualUI
import FoundationModels

// Forces recompilation for struct change
struct DebugView: View {
    @State private var selectedBrain: BrainType = .regex
    @State private var testFieldName = "Date of birth"
    @State private var analysisResult: InputDecision?
    @State private var isAnalyzing = false
    @State private var analysisLog: [String] = []
    @State private var appleIntelligenceAvailable: Bool? = nil
    
    enum BrainType: String, CaseIterable {
        case regex = "RegexBrain"
        case apple = "AppleIntelligence"
        case compare = "Compare (Side-by-Side)"
    }
    
    // Structure to hold comparison results
    struct ComparisonResult {
        var regex: InputDecision?
        var apple: InputDecision?
        var regexDuration: TimeInterval?
        var appleDuration: TimeInterval?
    }
    
    @State private var comparisonResult: ComparisonResult?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Brain") {
                    Picker("Brain", selection: $selectedBrain) {
                        ForEach(BrainType.allCases, id: \.self) { brain in
                            Text(brain.rawValue).tag(brain)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedBrain == .apple || selectedBrain == .compare {
                        AppleIntelligenceStatusView(isAvailable: appleIntelligenceAvailable)
                    }
                }
                
                Section("Test Field") {
                    TextField("Field name", text: $testFieldName)
                    
                    Button(action: runAnalysis) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Analyze")
                        }
                    }
                    .disabled(isAnalyzing || testFieldName.isEmpty || !canUseSelectedBrain)
                }
                
                if selectedBrain == .compare, let comparison = comparisonResult {
                    Section("Comparison Result") {
                        HStack(alignment: .top, spacing: 16) {
                            // Column 1: Regex
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Regex").font(.caption).bold().foregroundStyle(.secondary)
                                if let decision = comparison.regex {
                                    ResultCard(decision: decision, duration: comparison.regexDuration)
                                } else {
                                    Text("Failed").foregroundStyle(.red)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                            
                            // Column 2: Apple
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Apple AI").font(.caption).bold().foregroundStyle(.secondary)
                                if let decision = comparison.apple {
                                    ResultCard(decision: decision, duration: comparison.appleDuration)
                                } else {
                                    Text("Failed / N/A").foregroundStyle(.red)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                } else if let result = analysisResult, selectedBrain != .compare {
                    // ... Existing single result view ...
                    SingleResultSection(result: result)
                }
                
                Section("Log") {
                    if analysisLog.isEmpty {
                        Text("No analysis performed")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(analysisLog.reversed(), id: \.self) { entry in
                            Text(entry)
                                .font(.caption)
                                .fontDesign(.monospaced)
                        }
                    }
                }
            }
            .navigationTitle("Debug")
            .task {
                await checkAppleIntelligenceAvailability()
            }
        }
    }
    
    private var canUseSelectedBrain: Bool {
        if selectedBrain == .regex { return true }
        if selectedBrain == .compare { return true } // Can run at least regex
        return appleIntelligenceAvailable == true
    }
    
    private func checkAppleIntelligenceAvailability() async {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            let available = model.isAvailable
            await MainActor.run {
                appleIntelligenceAvailable = available
            }
        } else {
            await MainActor.run {
                appleIntelligenceAvailable = false
            }
        }
    }
    
    private func runAnalysis() {
        isAnalyzing = true
        analysisResult = nil
        comparisonResult = nil
        
        let context = FieldContext(name: testFieldName, type: "text")
        let brainSelection = selectedBrain // Capture current selection
        
        Task {
            if brainSelection == .compare {
                await runComparison(context: context)
            } else {
                await runSingleAnalysis(context: context, brainType: brainSelection)
            }
        }
    }
    
    private func runSingleAnalysis(context: FieldContext, brainType: BrainType) async {
        let startTime = Date()
        do {
            let decision: InputDecision
            
            if brainType == .apple {
                if #available(iOS 26.0, *) {
                    let brain = AppleIntelligenceBrain()
                    decision = try await brain.decide(for: context)
                } else {
                    throw ContextualError.aiNotAvailable
                }
            } else {
                let brain = RegexBrain()
                decision = try await brain.decide(for: context)
            }
            
            let duration = Date().timeIntervalSince(startTime) * 1000
            
            await MainActor.run {
                analysisResult = decision
                analysisLog.append("[\(brainType.rawValue)] \"\(testFieldName)\" → \(decision.strategy.rawValue) (\(String(format: "%.1f", duration))ms)")
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                analysisLog.append("❌ [\(brainType.rawValue)] Error: \(error.localizedDescription)")
                isAnalyzing = false
            }
        }
    }
    
    private func runComparison(context: FieldContext) async {
        async let regexTask = runBrainSafely(RegexBrain(), context: context)
        
        var appleResult: (InputDecision?, TimeInterval?) = (nil, nil)
        if appleIntelligenceAvailable == true, #available(iOS 26.0, *) {
            appleResult = await runBrainSafely(AppleIntelligenceBrain(), context: context)
        }
        
        let regexResult = await regexTask
        
        await MainActor.run {
            comparisonResult = ComparisonResult(
                regex: regexResult.0,
                apple: appleResult.0,
                regexDuration: regexResult.1,
                appleDuration: appleResult.1
            )
            
            let rTime = regexResult.1.map { String(format: "%.0fms", $0 * 1000) } ?? "err"
            let aTime = appleResult.1.map { String(format: "%.0fms", $0 * 1000) } ?? "n/a"
            
            analysisLog.append("⚖️ [Compare] Regex: \(rTime) vs AI: \(aTime)")
            isAnalyzing = false
        }
    }
    
    private func runBrainSafely(_ brain: ContextualBrain, context: FieldContext) async -> (InputDecision?, TimeInterval?) {
        let start = Date()
        do {
            let result = try await brain.decide(for: context)
            let duration = Date().timeIntervalSince(start)
            return (result, duration)
        } catch {
            return (nil, nil)
        }
    }
}

// MARK: - Subviews for Comparison

struct ResultCard: View {
    let decision: InputDecision
    let duration: TimeInterval?
    
    var body: some View {
        VStack(alignment: .leading) {
            StrategyIcon(strategy: decision.strategy)
                .scaleEffect(0.8)
            Text(decision.strategy.rawValue.capitalized)
                .font(.headline)
            Text(decision.label ?? "-")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let t = duration {
                Text(String(format: "%.0f ms", t * 1000))
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SingleResultSection: View {
    let result: InputDecision
    
    var body: some View {
        Section("Result Overview") {
            HStack {
                StrategyIcon(strategy: result.strategy)
                VStack(alignment: .leading) {
                    Text(result.strategy.rawValue.uppercased())
                        .font(.headline)
                    Text(result.label ?? "No label")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        
        Section("Live Preview") {
            VStack(alignment: .leading, spacing: 8) {
                Text("This is how the input looks and behaves:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Mock binding for preview
                let binding = Binding<String>(
                    get: { "" },
                    set: { _ in }
                )
                
                ContextualRenderer(decision: result, value: binding)
                    .padding(.vertical, 8)
            }
        }
        
        Section("Basic Properties") {
            LabeledContent("Strategy") {
                Text(result.strategy.rawValue)
                    .foregroundStyle(.blue)
                    .fontWeight(.medium)
            }
            LabeledContent("Label", value: result.label ?? "-")
            LabeledContent("Placeholder", value: result.placeholder ?? "-")
        }
        
        if let keyboard = result.keyboard {
            Section("Keyboard Configuration") {
                LabeledContent("Type", value: keyboard.type)
                if let contentType = keyboard.contentType {
                    LabeledContent("Content Type", value: contentType)
                }
                LabeledContent("Autocapitalization", value: keyboard.autocapitalization)
            }
        }
        
        if let native = result.native {
            Section("Native Control Configuration") {
                LabeledContent("Control Type", value: native.control)
                if let options = native.options, !options.isEmpty {
                    LabeledContent("Options") {
                        Text(options.joined(separator: ", "))
                            .font(.caption)
                    }
                }
            }
        }
        
        if let webview = result.webview {
            Section("WebView Configuration") {
                LabeledContent("HTML Length") {
                    Text("\(webview.html.count) chars")
                }
                Text(webview.html.prefix(200) + "...")
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            }
        }
        
        Section("Raw JSON") {
            if let jsonData = try? JSONEncoder().encode(result),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                Text(jsonString)
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Apple Intelligence Status View

struct AppleIntelligenceStatusView: View {
    let isAvailable: Bool?
    
    var body: some View {
        if let available = isAvailable {
            if available {
                Label("Apple Intelligence available", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Label("Apple Intelligence not available. Check Settings.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } else {
            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Checking availability...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Strategy Icon

struct StrategyIcon: View {
    let strategy: InputStrategy
    
    var body: some View {
        Image(systemName: iconName)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var iconName: String {
        switch strategy {
        case .keyboard: return "keyboard"
        case .native: return "slider.horizontal.3"
        case .signature: return "signature"
        case .webview: return "globe"
        case .map: return "map"
        }
    }
    
    private var color: Color {
        switch strategy {
        case .keyboard: return .blue
        case .native: return .purple
        case .signature: return .indigo
        case .webview: return .orange
        case .map: return .green
        }
    }
}

// MARK: - Helper Functions

extension DebugView {
    func keyboardIcon(_ type: String) -> String {
        switch type {
        case "email": return "envelope"
        case "phone": return "phone"
        case "number": return "number"
        case "decimal": return "number.circle"
        case "url": return "link"
        default: return "keyboard"
        }
    }
    
    func nativeIcon(_ control: String) -> String {
        switch control {
        case "datePicker": return "calendar"
        case "colorPicker": return "paintpalette"
        case "toggle": return "switch.2"
        case "slider": return "slider.horizontal.3"
        case "picker": return "list.bullet"
        case "stepper": return "plus.forwardslash.minus"
        default: return "square.dashed"
        }
    }
    
    func formatJSON(_ json: String) -> String {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return json
        }
        return prettyString
    }
}

#Preview {
    DebugView()
}
