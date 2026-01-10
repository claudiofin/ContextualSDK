//
//  ControlsDemoView.swift
//  SampleApp
//
//  Showcases all SDK controls: SignatureView, ColorInputView, ViewModifiers
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence
import ContextualUI

struct ControlsDemoView: View {
    // State for demos
    @State private var signatureData: Data? = nil
    @State private var selectedColor: Color = .blue
    @State private var colorOutput: ColorOutput? = nil
    @State private var generativeValue = ""
    @State private var contextualValue = ""
    @State private var isSheetPresented = false
    @State private var sheetValue = ""
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - SignatureView Demo
                Section {
                    SignatureView(signatureData: $signatureData)
                    
                    if let data = signatureData {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Signature captured: \(data.count) bytes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Signature (PencilKit)", systemImage: "signature")
                }
                
                // MARK: - ColorInputView Demo
                Section {
                    ColorInputView(selectedColor: $selectedColor, colorOutput: $colorOutput)
                    
                    if let output = colorOutput {
                        HStack {
                            Circle()
                                .fill(output.color)
                                .frame(width: 24, height: 24)
                            Text("\(output.name) - \(output.hex)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Color Picker", systemImage: "paintpalette")
                }
                
                // MARK: - ViewModifier Demo
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Using .contextualInput() modifier:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Field: Email Address")
                            .contextualInput(
                                fieldName: "Email Address:",
                                value: $contextualValue
                            )
                    }
                    
                    if !contextualValue.isEmpty {
                        Text("Value: \(contextualValue)")
                            .font(.caption)
                    }
                } header: {
                    Label("ViewModifier", systemImage: "wand.and.stars")
                }
                
                // MARK: - Generative Input Demo
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Using .generativeInput() modifier:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Prompt: Rate from 1 to 5 stars")
                            .generativeInput(
                                prompt: "Rate from 1 to 5 stars",
                                value: $generativeValue
                            )
                    }
                    
                    if !generativeValue.isEmpty {
                        Text("Rating: \(generativeValue)")
                            .font(.caption)
                    }
                } header: {
                    Label("Generative Input", systemImage: "sparkles")
                }
                
                // MARK: - Bottom Sheet Demo
                Section {
                    Button {
                        isSheetPresented = true
                    } label: {
                        Label("Open Input Sheet", systemImage: "rectangle.bottomhalf.filled")
                    }
                    
                    if !sheetValue.isEmpty {
                        Text("Sheet value: \(sheetValue)")
                            .font(.caption)
                    }
                } header: {
                    Label("Input Sheet", systemImage: "doc.text")
                }
            }
            .navigationTitle("Controls Demo")
            .sheet(isPresented: $isSheetPresented) {
                NavigationStack {
                    ContextualInputSheet(
                        decision: InputDecision(
                            strategy: .keyboard,
                            label: "Notes",
                            placeholder: "Enter your notes here..."
                        ),
                        value: $sheetValue,
                        fieldLabel: "Notes Field",
                        onConfirm: {
                            isSheetPresented = false
                        },
                        onDismiss: {
                            isSheetPresented = false
                        }
                    )
                }
                .presentationDetents([.medium])
            }
            // MARK: - Custom Renderer Demo
            Section {
                NavigationLink("Glassmorphic Renderer (Map Demo)") {
                    CustomRendererDemo()
                }
            } header: {
                Label("Custom UI", systemImage: "paintpalette.fill")
            }
        }
    }
}

#Preview {
    ControlsDemoView()
}
