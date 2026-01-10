//
//  ContextualInputSheet.swift
//  ContextualUI
//
//  Bottom sheet for input controls
//

import SwiftUI
import ContextualSDK

public struct ContextualInputSheet: View {
    let decision: InputDecision
    @Binding var value: String
    let fieldLabel: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    public init(
        decision: InputDecision,
        value: Binding<String>,
        fieldLabel: String = "",
        onConfirm: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.decision = decision
        self._value = value
        self.fieldLabel = fieldLabel
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundStyle(.red)
                
                Spacer()
                
                Text(decision.label ?? fieldLabel)
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    onConfirm()
                }
                .fontWeight(.semibold)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    ContextualRenderer(decision: decision, value: $value)
                        .padding()
                }
            }
            .frame(maxHeight: 400)
        }
        .background(.regularMaterial)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var value = ""
        @State var showing = true
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.3)
                
                if showing {
                    VStack {
                        Spacer()
                        ContextualInputSheet(
                            decision: InputDecision(strategy: .keyboard, label: "Email", placeholder: "email@example.com"),
                            value: $value,
                            fieldLabel: "Email Field",
                            onConfirm: { showing = false },
                            onDismiss: { showing = false }
                        )
                    }
                }
            }
        }
    }
    return PreviewWrapper()
}
