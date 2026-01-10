//
//  WebViewGalleryView.swift
//  SampleApp
//
//  Unified gallery of all WebView input examples
//

import SwiftUI
import ContextualSDK
import ContextualUI

struct WebViewGalleryView: View {
    @State private var locationValue = ""
    @State private var customFormValue = ""
    @State private var ratingValue = ""
    @State private var colorValue = "#007AFF"
    @State private var multiSelectValue = ""
    @State private var paymentValue = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("WebView inputs allow for completely custom UI while maintaining native data binding.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Group 1: Complex Inputs
                Section("Interactive Widgets") {
                    
                    // Location Picker
                    NavigationLink {
                        WebViewContainer(
                            title: "Location Picker",
                            description: "Mock Google Maps integration using HTML select.",
                            decision: InputDecision(
                                strategy: .webview,
                                label: "Select Location",
                                webview: WebViewConfig(html: """
                                    <h3>📍 Location Picker</h3>
                                    <p>Select your city:</p>
                                    <select onchange="sendValue(this.value)" style="font-size: 18px; padding: 10px; width: 100%;">
                                        <option value="">-- Select --</option>
                                        <option value="Milano">Milano</option>
                                        <option value="Roma">Roma</option>
                                        <option value="Napoli">Napoli</option>
                                        <option value="Torino">Torino</option>
                                        <option value="Firenze">Firenze</option>
                                    </select>
                                """)
                            ),
                            value: $locationValue
                        )
                    } label: {
                        Label("Location Picker", systemImage: "map")
                    }
                    
                    // Star Rating
                    NavigationLink {
                        WebViewContainer(
                            title: "Star Rating",
                            description: "Custom JS-driven rating component.",
                            decision: InputDecision(
                                strategy: .webview,
                                label: "Rate Us",
                                webview: WebViewConfig(html: """
                                    <style>
                                        .stars { font-size: 40px; cursor: pointer; display: flex; justify-content: center; gap: 10px; }
                                        .star { color: #444; transition: color 0.2s; }
                                        .star.active { color: #FFD700; }
                                        body { background: transparent; color: white; font-family: -apple-system; text-align: center; }
                                    </style>
                                    <div class="stars">
                                        <span class="star" onclick="rate(1)">★</span>
                                        <span class="star" onclick="rate(2)">★</span>
                                        <span class="star" onclick="rate(3)">★</span>
                                        <span class="star" onclick="rate(4)">★</span>
                                        <span class="star" onclick="rate(5)">★</span>
                                    </div>
                                    <p id="rating-text" style="color: #888; margin-top: 10px;">Tap to rate</p>
                                    <script>
                                        function rate(n) {
                                            const stars = document.querySelectorAll('.star');
                                            stars.forEach((s, i) => {
                                                s.classList.toggle('active', i < n);
                                            });
                                            document.getElementById('rating-text').textContent = n + '/5';
                                            sendValue(n.toString());
                                        }
                                    </script>
                                """)
                            ),
                            value: $ratingValue
                        )
                    } label: {
                        Label("Star Rating", systemImage: "star.fill")
                    }
                }
                
                // MARK: - Group 2: Form Elements
                Section("Form Elements") {
                    
                    // Advanced Color Picker
                    NavigationLink {
                        WebViewContainer(
                            title: "Advanced Color Picker",
                            description: "Hybrid palette + native color input.",
                            decision: InputDecision(
                                strategy: .webview,
                                label: "Brand Color",
                                webview: WebViewConfig(html: """
                                    <div style="padding: 20px; font-family: -apple-system; text-align: center;">
                                        <div style="display: flex; gap: 15px; justify-content: center; margin-bottom: 20px;">
                                            <div onclick="select('#FF3B30')" style="width: 50px; height: 50px; background: #FF3B30; border-radius: 25px; cursor: pointer; border: 2px solid white;"></div>
                                            <div onclick="select('#007AFF')" style="width: 50px; height: 50px; background: #007AFF; border-radius: 25px; cursor: pointer; border: 2px solid white;"></div>
                                            <div onclick="select('#34C759')" style="width: 50px; height: 50px; background: #34C759; border-radius: 25px; cursor: pointer; border: 2px solid white;"></div>
                                        </div>
                                        <input type="color" onchange="select(this.value)" style="width: 100%; height: 50px; border: none; background: none; cursor: pointer;">
                                        <p id="selected" style="color: white; margin-top: 20px; font-weight: bold; font-size: 20px;">#______</p>
                                    </div>
                                    <script>
                                        function select(color) {
                                            document.getElementById('selected').innerText = color;
                                            document.getElementById('selected').style.color = color;
                                            sendValue(color);
                                        }
                                    </script>
                                """)
                            ),
                            value: $colorValue
                        )
                    } label: {
                        Label("Advanced Color Picker", systemImage: "paintpalette.fill")
                    }
                    
                    // Multi-Select Tags
                    NavigationLink {
                        WebViewContainer(
                            title: "Multi-Select Tags",
                            description: "Interactive tag selection cloud.",
                            decision: InputDecision(
                                strategy: .webview,
                                label: "Interests",
                                webview: WebViewConfig(html: """
                                    <style>
                                        .tag { 
                                            display: inline-block; 
                                            padding: 8px 16px; 
                                            margin: 6px; 
                                            background: #333; 
                                            color: white; 
                                            border-radius: 20px; 
                                            font-size: 16px;
                                            cursor: pointer;
                                            border: 1px solid #444;
                                            User-select: none;
                                        }
                                        .tag.selected { 
                                            background: #007AFF; 
                                            border-color: #007AFF; 
                                        }
                                        body { font-family: -apple-system; padding: 10px; }
                                    </style>
                                    <div id="container"></div>
                                    <script>
                                        const options = ['Swift', 'SwiftUI', 'UIKit', 'CoreData', 'Combine', 'Metal', 'Vapor', 'ARKit'];
                                        const selected = new Set();
                                        
                                        const container = document.getElementById('container');
                                        options.forEach(opt => {
                                            const el = document.createElement('div');
                                            el.className = 'tag';
                                            el.innerText = opt;
                                            el.onclick = () => {
                                                if (selected.has(opt)) selected.delete(opt);
                                                else selected.add(opt);
                                                el.classList.toggle('selected');
                                                sendValue(Array.from(selected).join(', '));
                                            };
                                            container.appendChild(el);
                                        });
                                    </script>
                                """)
                            ),
                            value: $multiSelectValue
                        )
                    } label: {
                        Label("Multi-Select Tags", systemImage: "tag.fill")
                    }
                    
                    // Credit Card
                    NavigationLink {
                        WebViewContainer(
                            title: "Credit Card Input",
                            description: "Visual credit card form with auto-formatting.",
                            decision: InputDecision(
                                strategy: .webview,
                                label: "Payment Method",
                                webview: WebViewConfig(html: """
                                    <div style="font-family: monospace; background: linear-gradient(135deg, #333, #111); padding: 20px; border-radius: 15px; border: 1px solid #444; color: white;">
                                        <div style="display: flex; justify-content: space-between; margin-bottom: 30px;">
                                            <span style="color: #aaa; font-size: 14px;">CREDIT CARD</span>
                                            <span style="font-weight: bold;">VISA</span>
                                        </div>
                                        <input type="text" placeholder="0000 0000 0000 0000" 
                                            style="width: 100%; background: none; border: none; color: white; font-size: 24px; letter-spacing: 3px; outline: none; margin-bottom: 20px;"
                                            onkeyup="format(this)"
                                        >
                                        <div style="display: flex; justify-content: space-between;">
                                            <div>
                                                <div style="font-size: 10px; color: #aaa;">EXPIRES</div>
                                                <input type="text" placeholder="MM/YY" style="width: 60px; background: none; border: none; color: white; font-size: 16px; outline: none;">
                                            </div>
                                            <div>
                                                <div style="font-size: 10px; color: #aaa;">CVC</div>
                                                <input type="text" placeholder="123" style="width: 40px; background: none; border: none; color: white; font-size: 16px; outline: none;">
                                            </div>
                                        </div>
                                    </div>
                                    <script>
                                        function format(input) {
                                            let v = input.value.replace(/\\s+/g, '').replace(/[^0-9]/gi, '');
                                            let matches = v.match(/\\d{4,16}/g);
                                            let match = matches && matches[0] || '';
                                            let parts = [];
                                            for (let i=0, len=match.length; i<len; i+=4) {
                                                parts.push(match.substring(i, i+4));
                                            }
                                            if (parts.length) {
                                                input.value = parts.join(' ');
                                                sendValue(input.value);
                                            } else {
                                                input.value = v;
                                                sendValue(v);
                                            }
                                        }
                                    </script>
                                """)
                            ),
                            value: $paymentValue
                        )
                    } label: {
                        Label("Credit Card Input", systemImage: "creditcard.fill")
                    }
                }
            }
            .navigationTitle("WebView Gallery")
        }
    }
}

// Helper Container for Gallery Detail Views
struct WebViewContainer: View {
    let title: String
    let description: String
    let decision: InputDecision
    @Binding var value: String
    
    var body: some View {
        Form {
            Section {
                Text(description)
                    .foregroundStyle(.secondary)
            }
            
            Section("Preview") {
                ContextualRenderer(decision: decision, value: $value)
                    .frame(minHeight: 200) // Ensure enough space for WebView content
            }
            
            Section("Value") {
                Text(value.isEmpty ? "No interaction yet" : value)
                    .font(.monospaced(.body)())
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WebViewGalleryView()
}
