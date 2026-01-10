//
//  Renderer.swift
//  ContextualUI
//
//  Created by ContextualSDK.
//

import SwiftUI
import ContextualSDK
import WebKit

#if canImport(UIKit)
import UIKit
#endif

public struct ContextualRenderer: View {
    let decision: InputDecision
    @Binding var value: String
    
    public init(decision: InputDecision, value: Binding<String>) {
        self.decision = decision
        self._value = value
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            header
            
            switch decision.strategy {
            case .keyboard:
                renderKeyboard()
            case .native:
                renderNative()
            case .signature:
                renderSignature()
            case .webview:
                renderWebView()
            case .map:
                renderMap()
            }
        }
        .padding()
        .background(backgroundStyle)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    private var backgroundStyle: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack {
            if let label = decision.label {
                Text(label)
                    .font(.headline)
            }
            Spacer()
            StrategyBadge(strategy: decision.strategy)
        }
    }
    
    @ViewBuilder
    private func renderKeyboard() -> some View {
        TextField(decision.placeholder ?? "Enter text", text: $value)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .autocapitalization(decision.keyboard?.autocapitalization == "none" ? .none : .sentences)
            .keyboardType(keyboardType)
            .modifier(KeyboardToolbarModifier(needsToolbar: needsDismissToolbar))
            #endif
    }
    
    #if os(iOS)
    /// Only show toolbar for keyboards without a return/done key
    private var needsDismissToolbar: Bool {
        switch decision.keyboard?.type {
        case "number", "phone", "decimal":
            return true
        default:
            return false
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch decision.keyboard?.type {
        case "email": return .emailAddress
        case "phone": return .phonePad
        case "number": return .numberPad
        case "decimal": return .decimalPad
        case "url": return .URL
        default: return .default
        }
    }
    #endif
    
    @ViewBuilder
    private func renderNative() -> some View {
        Group {
            if let config = decision.native {
                switch config.control {
                case "datePicker":
                    DatePicker("Date", selection: Binding(
                        get: { 
                            // Avoid returning Date() directly as it causes infinite diff loops
                            let formatter = DateFormatter()
                            formatter.dateStyle = .medium
                            return formatter.date(from: value) ?? Date.now
                        },
                        set: { value = $0.formatted(date: .numeric, time: .omitted) }
                    ), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    
                case "colorPicker":
                    ColorInputViewWrapper(value: $value)
                    
                case "toggle":
                    Toggle(decision.label ?? "Option", isOn: Binding(
                        get: { value == "true" || value == "[x]" },
                        set: { value = $0 ? "[x]" : "[ ]" }
                    ))
                    
                case "slider":
                    let range = config.range ?? [0, 100, 1]
                    let minVal = range.count > 0 ? range[0] : 0
                    let maxVal = range.count > 1 ? range[1] : 100
                    
                    VStack {
                        HStack {
                            Text("\(Int(Double(value) ?? minVal))")
                                .font(.title.bold())
                            if let unit = config.unit {
                                Text(unit)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Slider(value: Binding(
                            get: { Double(value) ?? minVal },
                            set: { value = String(Int($0)) }
                        ), in: minVal...maxVal)
                    }
                    
                case "picker":
                    if let options = config.options, !options.isEmpty {
                        Picker(decision.label ?? "Select", selection: $value) {
                            Text("Select...").tag("")
                            ForEach(options, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text("No options available")
                    }
                    
                case "stepper":
                    let range = config.range ?? [0, 100, 1]
                    let step = range.count > 2 ? range[2] : 1
                    
                    Stepper(value: Binding(
                        get: { Double(value) ?? 0 },
                        set: { value = String(Int($0)) }
                    ), in: range[0]...range[1], step: step) {
                        Text("\(Int(Double(value) ?? 0))")
                    }
                    
                default:
                    Text("Unknown control: \(config.control)")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Native config missing")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func renderSignature() -> some View {
        #if os(iOS)
        SignatureViewWrapper(value: $value)
        #else
        VStack {
            Text("Signature not available on macOS")
                .foregroundStyle(.secondary)
        }
        .frame(height: 180)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        #endif
    }
    
    @ViewBuilder
    private func renderWebView() -> some View {
        if let config = decision.webview {
            WebContentView(html: config.html, value: $value)
                .frame(height: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        } else {
            VStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("WebView config missing")
                    .foregroundStyle(.secondary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func renderMap() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Map Strategy")
                .font(.headline)
            Text(decision.map?.showUserLocation == true ? "User Location Enabled" : "Static Map")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Signature Wrapper

#if os(iOS)
struct SignatureViewWrapper: View {
    @Binding var value: String
    @State private var signatureData: Data? = nil
    
    var body: some View {
        VStack {
            SignatureView(signatureData: $signatureData)
        }
        .onChange(of: signatureData) { _, newData in
            if let data = newData {
                value = "sig_\(data.count)_\(Date().timeIntervalSince1970)"
            } else {
                value = ""
            }
        }
    }
}
#endif

// MARK: - Color Input Wrapper

struct ColorInputViewWrapper: View {
    @Binding var value: String
    @State private var selectedColor: Color = .blue
    @State private var colorOutput: ColorOutput? = nil
    
    var body: some View {
        ColorInputView(selectedColor: $selectedColor, colorOutput: $colorOutput)
            .onChange(of: colorOutput) { _, newOutput in
                if let output = newOutput {
                    value = output.hex
                }
            }
    }
}

// MARK: - WebView Wrapper

#if os(iOS)
struct WebContentView: UIViewRepresentable {
    let html: String
    @Binding var value: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "contextualHandler")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { font-family: -apple-system; margin: 16px; }
                input, select, textarea { font-size: 16px; padding: 8px; width: 100%; box-sizing: border-box; margin: 4px 0; }
                button { font-size: 16px; padding: 10px 20px; background: #007AFF; color: white; border: none; border-radius: 8px; }
            </style>
        </head>
        <body>
            \(html)
            <script>
                function sendValue(val) {
                    window.webkit.messageHandlers.contextualHandler.postMessage(val);
                }
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebContentView
        
        init(_ parent: WebContentView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let value = message.body as? String {
                DispatchQueue.main.async {
                    self.parent.value = value
                }
            }
        }
    }
}
#else
struct WebContentView: View {
    let html: String
    @Binding var value: String
    
    var body: some View {
        Text("WebView not available on this platform")
            .foregroundStyle(.secondary)
    }
}
#endif

// MARK: - Strategy Badge

struct StrategyBadge: View {
    let strategy: InputStrategy
    
    var body: some View {
        Text(strategy.rawValue.uppercased())
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var badgeColor: Color {
        switch strategy {
        case .keyboard: return .blue
        case .native: return .purple
        case .signature: return .indigo
        case .webview: return .orange
        case .map: return .green
        }
    }
}

// MARK: - Keyboard Toolbar Modifier

#if os(iOS)
/// Only shows toolbar with Done button for keyboards that don't have a return key
struct KeyboardToolbarModifier: ViewModifier {
    let needsToolbar: Bool
    
    func body(content: Content) -> some View {
        if needsToolbar {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                    }
                }
        } else {
            content
        }
    }
}
#else
struct KeyboardToolbarModifier: ViewModifier {
    let needsToolbar: Bool
    func body(content: Content) -> some View { content }
}
#endif
