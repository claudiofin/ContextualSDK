//
//  PDFFormView.swift
//  SampleApp
//
//  Simulates a bureaucratic PDF form with mixed field types
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence
import ContextualUI

struct PDFFormView: View {
    // Field values
    @State private var acceptTerms = ""
    @State private var signature = ""
    @State private var currentDate = ""
    @State private var amount = ""
    @State private var notes = ""
    
    // Analysis
    let brain = RegexBrain()
    @State private var decisions: [String: InputDecision] = [:]
    @State private var isLoading = true
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("REQUEST FORM")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                
                Section("Request Details") {
                    fieldView("currentDate", label: "Date")
                    fieldView("amount", label: "Amount")
                }
                
                Section("Notes") {
                    fieldView("notes", label: "Additional Notes")
                }
                
                Section("Declarations") {
                    fieldView("acceptTerms", label: "Terms")
                    
                    Text("I declare that I have read and accepted the terms and conditions of service.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Signature") {
                    fieldView("signature", label: "Signature")
                }
                
                Section {
                    Button(action: submitForm) {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Submit Form")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("PDF Form")
            .task { await analyzeAllFields() }
            .overlay {
                if isLoading {
                    ProgressView("Loading form...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .alert("Form Submitted", isPresented: $showSuccess) {
                Button("OK") { resetForm() }
            } message: {
                Text("The form has been submitted successfully.")
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
        case "acceptTerms": return $acceptTerms
        case "signature": return $signature
        case "currentDate": return $currentDate
        case "amount": return $amount
        case "notes": return $notes
        default: return .constant("")
        }
    }
    
    private var canSubmit: Bool {
        (acceptTerms == "[x]" || acceptTerms == "true") && !signature.isEmpty
    }
    
    private func submitForm() {
        print("📄 PDF Form submitted:")
        print("  Date: \(currentDate)")
        print("  Amount: \(amount)")
        print("  Terms: \(acceptTerms)")
        print("  Signature: \(signature)")
        showSuccess = true
    }
    
    private func resetForm() {
        acceptTerms = ""
        signature = ""
        currentDate = ""
        amount = ""
        notes = ""
    }
    
    private func analyzeAllFields() async {
        // Fast path for UI testing
        if AppConfig.isUITesting {
            decisions = AppConfig.mockPDFDecisions
            isLoading = false
            return
        }
        
        let fields: [(String, FieldContext)] = [
            ("currentDate", FieldContext(name: "Current date", type: "text")),
            ("amount", FieldContext(name: "Requested amount ($)", type: "text")),
            ("notes", FieldContext(name: "Notes:", type: "text")),
            ("acceptTerms", FieldContext(name: "Accept terms [ ]", type: "text")),
            ("signature", FieldContext(name: "Applicant signature", type: "signature"))
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
    PDFFormView()
}
