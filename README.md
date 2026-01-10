# ContextualSDK 🧠✨

![ContextualSDK Icon](contextual_sdk_icon.png)

**ContextualSDK** is an intelligent, agentic iOS framework that dynamically adapts your app's input fields using **Apple Intelligence** (with robust Regex fallbacks). It acts as an agent that understands the context of a field and renders the perfect UI for it, eliminating manual configuration.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Philosophy: The "Agentic Input" Approach 🤖

Traditional development requires you to manually choose the right input tool for every scenario: `DatePicker` for dates, `ColorPicker` for colors, `TextField` with specific content types for emails, etc.

**ContextualSDK flips this model.**

Instead of pre-configuring inputs, you simply tell the SDK: *"Here is a field, and here is its context."* 
The SDK, powered by Apple Intelligence (Foundation Models), acts as an intelligent agent. It analyzes the field name, surrounding text, and type hints to **decide** the best input strategy for you.

> "There are many input tools already available. Why configure them manually? Let an agent on Apple Foundation make the right choices for us."

## Use Cases 🚀

### 📄 The Intelligent PDF Editor
Imagine building a PDF editor where users can drag and drop "fill boxes" onto a document.
*   **Without ContextualSDK**: You have to ask the user "Is this a text field? A date? A signature?" or use complex heuristics.
*   **With ContextualSDK**: You simply create a generic "Fill Box". When the user places it near text like "Date of Birth" or "Signature", **ContextualSDK automatically renders a Date Picker or a Signature Pad**. You don't write a single line of conditional logic.

### 🪄 Zero-Code Forms
Generate entire forms from a list of strings. If your backend sends `["Birth Date", "Favorite Color", "Home Address"]`, ContextualSDK renders a DatePicker, a ColorPicker, and a Map View automatically.

## Features

- **🧠 Apple Intelligence Integration**: Uses on-device models to analyze field context (name, nearby text) and pick the best input strategy.
- **⚡️ Instant Regex Fallback**: Works offline and instantly using a powerful rule-based engine when AI is unavailable.
- **🎨 Dynamic Rendering**: Automatically renders `DatePicker`, `ColorPicker`, `Maps`, `Signatures`, or even custom `WebViews`.
- **🔒 Privacy First**: All analysis happens on-device. No data leaves the user's phone.
- **🛠️ Debug Tools**: built-in `DebugView` to compare AI vs. Regex logic side-by-side.

## Requirements

- **iOS 26.0+**
- **Xcode 16.0+**
- **Apple Intelligence Support**: Requires iPhone 15 Pro/Pro Max, or iPad/Mac with M1 chip or later.
    - *Note:* If the device does not support Apple Intelligence, the SDK **automatically falls back** to the high-performance Regex engine. No code changes required.

## Installation

### Swift Package Manager

Add `ContextualSDK` to your project via Xcode:

1. File > Add Packages...
2. Enter repository URL: `https://github.com/your-org/ContextualSDK`
3. Select **Up to Next Major Version** (e.g. 1.0.0)

## Quick Start

1. **Import the Framework**
   ```swift
   import ContextualSDK
   import ContextualIntelligence
   import ContextualUI
   ```

2. **Define a Context**
   Tell the SDK about the field you want to render.
   ```swift
   let context = FieldContext(
       name: "Date of Birth",
       type: "text", // e.g., from an HTML form
       nearbyText: "Please enter your birth date to continue."
   )
   ```

3. **Analyze & Render**
   Use `AppleIntelligenceBrain` (or `RegexBrain`) to decide the UI, then render it with `ContextualRenderer`.

   ```swift
   struct MyFormView: View {
       @State private var value = ""
       @State private var decision: InputDecision?

       var body: some View {
           VStack {
               if let decision = decision {
                   ContextualRenderer(decision: decision, value: $value)
               } else {
                   ProgressView("Analyzing...")
               }
           }
           .task {
               // The SDK automatically handles fallback if AI is unavailable
               let brain = AppleIntelligenceBrain() 
               self.decision = try? await brain.decide(for: context)
           }
       }
   }
   ```

## Advanced Usage

### Side-by-Side Debugging
Use the included `DebugView` to verify how different engines interpret your fields.

```swift
import ContextualSDK
// In your debug menu
DebugView()
```

### Custom Logging
The SDK uses `OSLog` for unified logging. You can filter logs in Console.app using:
- Subsystem: `com.contextual.sdk`
- Categories: `Brain`, `UI`, `Core`

## Contributing

Pull requests are welcome! Please ensure you run the `DebugView` comparison before submitting logic changes to the Regex engine.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
