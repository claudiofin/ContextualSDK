//
//  CustomRenderer.swift
//  SampleApp
//
//  Example of how to create a custom branded renderer
//

import SwiftUI
import ContextualSDK

/// A custom renderer with glassmorphism styling
struct GlassmorphicRenderer: View {
    let decision: InputDecision
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with gradient
            HStack {
                Circle()
                    .fill(strategyGradient)
                    .frame(width: 8, height: 8)
                
                Text(decision.label ?? "Campo")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(decision.strategy.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(strategyGradient)
                    .clipShape(Capsule())
            }
            
            // Input field with glass effect
            Group {
                switch decision.strategy {
                case .keyboard:
                    TextField(decision.placeholder ?? "...", text: $value)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                    
                case .native:
                    if decision.native?.control == "toggle" {
                        Toggle(isOn: Binding(
                            get: { value == "[x]" },
                            set: { value = $0 ? "[x]" : "[ ]" }
                        )) {
                            Text("Attivo")
                        }
                        .toggleStyle(.switch)
                        .tint(.purple)
                    } else {
                        Text("Native: \(decision.native?.control ?? "?")")
                            .foregroundStyle(.secondary)
                    }
                    
                case .signature:
                    VStack {
                        Text("✍️ Tap per firmare")
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                case .webview:
                    Text("WebView non supportato in custom renderer")
                        .foregroundStyle(.secondary)
                        
                case .map:
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                        Text("Mappa")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.green.opacity(0.3)) // Placeholder for map
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    private var strategyGradient: LinearGradient {
        switch decision.strategy {
        case .keyboard:
            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
        case .native:
            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
        case .signature:
            LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
        case .webview:
            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        case .map:
            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Demo View

struct CustomRendererDemo: View {
    @State private var name = ""
    @State private var acceptTerms = ""
    @State private var signature = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Custom Glassmorphic Renderer")
                    .font(.headline)
                
                GlassmorphicRenderer(
                    decision: InputDecision(strategy: .keyboard, label: "Nome Completo", placeholder: "Inserisci nome"),
                    value: $name
                )
                
                GlassmorphicRenderer(
                    decision: {
                        var d = InputDecision(strategy: .native, label: "Termini")
                        d.native = NativeConfig(control: "toggle")
                        return d
                    }(),
                    value: $acceptTerms
                )
                
                GlassmorphicRenderer(
                    decision: InputDecision(strategy: .signature, label: "Firma"),
                    value: $signature
                )
                
                GlassmorphicRenderer(
                    decision: InputDecision(strategy: .map, label: "Indirizzo", map: MapConfig(showUserLocation: true)),
                    value: .constant("")
                )
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.2, green: 0.1, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

#Preview {
    CustomRendererDemo()
}
