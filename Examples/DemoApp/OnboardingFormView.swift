//
//  OnboardingFormView.swift
//  SampleApp
//
//  Realistic onboarding form with 9 fields
//

import SwiftUI
import ContextualSDK
import ContextualIntelligence
import ContextualUI

struct OnboardingFormView: View {
    // Field values
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var birthDate = ""
    @State private var taxCode = ""
    @State private var address = ""
    @State private var postalCode = ""
    @State private var province = ""
    
    // Analysis
    let brain = RegexBrain()
    @State private var decisions: [String: InputDecision] = [:]
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Data") {
                    fieldView("firstName", label: "First Name")
                    fieldView("lastName", label: "Last Name")
                    fieldView("birthDate", label: "Date of Birth")
                    fieldView("taxCode", label: "Tax Code")
                }
                
                Section("Contact Info") {
                    fieldView("email", label: "Email")
                    fieldView("phone", label: "Phone")
                }
                
                Section("Address") {
                    fieldView("address", label: "Street")
                    fieldView("postalCode", label: "Postal Code")
                    fieldView("province", label: "State/Province")
                }
                
                Section {
                    Button(action: submitForm) {
                        HStack {
                            Spacer()
                            Text("Confirm Registration")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Registration")
            .task { await analyzeAllFields() }
            .overlay {
                if isLoading {
                    ProgressView("Analyzing fields...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
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
        case "firstName": return $firstName
        case "lastName": return $lastName
        case "email": return $email
        case "phone": return $phone
        case "birthDate": return $birthDate
        case "taxCode": return $taxCode
        case "address": return $address
        case "postalCode": return $postalCode
        case "province": return $province
        default: return .constant("")
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
    }
    
    private func submitForm() {
        print("📋 Form submitted:")
        print("  Name: \(firstName) \(lastName)")
        print("  Email: \(email)")
        print("  Phone: \(phone)")
        print("  Tax Code: \(taxCode)")
    }
    
    private func analyzeAllFields() async {
        // Fast path for UI testing
        if AppConfig.isUITesting {
            decisions = AppConfig.mockOnboardingDecisions
            isLoading = false
            return
        }
        
        let fields: [(String, FieldContext)] = [
            ("firstName", FieldContext(name: "First Name:", type: "text")),
            ("lastName", FieldContext(name: "Last Name:", type: "text")),
            ("email", FieldContext(name: "E-mail:", type: "text")),
            ("phone", FieldContext(name: "Phone:", type: "text")),
            ("birthDate", FieldContext(name: "Date of birth", type: "text")),
            ("taxCode", FieldContext(name: "Tax Code:", type: "text")),
            ("address", FieldContext(name: "Address:", type: "text")),
            ("postalCode", FieldContext(name: "Postal Code:", type: "text")),
            ("province", FieldContext(name: "State:", type: "text"))
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
    OnboardingFormView()
}
