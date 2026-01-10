//
//  SettingsFormView.swift
//  SampleApp
//
//  Settings page with native controls
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence
import ContextualUI

struct SettingsFormView: View {
    // Settings values
    @State private var theme = ""
    @State private var volume = ""
    @State private var accentColor = ""
    @State private var notifications = ""
    
    // Analysis
    let brain = RegexBrain()
    @State private var decisions: [String: InputDecision] = [:]
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    fieldView("theme", label: "Theme")
                    fieldView("accentColor", label: "Color")
                }
                
                Section("Audio") {
                    fieldView("volume", label: "Volume")
                }
                
                Section("Notifications") {
                    fieldView("notifications", label: "Push")
                }
                
                Section("Current Values") {
                    LabeledContent("Theme", value: theme.isEmpty ? "-" : theme)
                    LabeledContent("Volume", value: volume.isEmpty ? "-" : "\(volume)%")
                    LabeledContent("Color", value: accentColor.isEmpty ? "-" : accentColor)
                    LabeledContent("Notifications", value: notifications.isEmpty ? "-" : notifications)
                }
            }
            .navigationTitle("Settings")
            .task { await analyzeAllFields() }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func fieldView(_ key: String, label: String) -> some View {
        if let decision = decisions[key] {
            ContextualRenderer(decision: decision, value: binding(for: key))
        } else {
            HStack {
                Text(label)
                Spacer()
                ProgressView()
            }
        }
    }
    
    private func binding(for key: String) -> Binding<String> {
        switch key {
        case "theme": return $theme
        case "volume": return $volume
        case "accentColor": return $accentColor
        case "notifications": return $notifications
        default: return .constant("")
        }
    }
    
    private func analyzeAllFields() async {
        // Fast path for UI testing
        if AppConfig.isUITesting {
            decisions = AppConfig.mockSettingsDecisions
            isLoading = false
            return
        }
        
        let fields: [(String, FieldContext)] = [
            ("theme", FieldContext(name: "App theme", type: "text")),
            ("volume", FieldContext(name: "Volume level (%)", type: "text")),
            ("accentColor", FieldContext(name: "Accent color", type: "text")),
            ("notifications", FieldContext(name: "Accept notifications [ ]", type: "text"))
        ]
        
        for (key, context) in fields {
            if let decision = try? await brain.decide(for: context) {
                decisions[key] = decision
            }
        }
        
        isLoading = false
    }
}

#Preview {
    SettingsFormView()
}
