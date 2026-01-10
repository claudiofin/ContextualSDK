//
//  ColorInputView.swift
//  ContextualUI
//
//  Enhanced color picker with presets
//

import SwiftUI
import ContextualSDK

public struct ColorInputView: View {
    @Binding var selectedColor: Color
    @Binding var colorOutput: ColorOutput?
    
    public init(selectedColor: Binding<Color>, colorOutput: Binding<ColorOutput?> = .constant(nil)) {
        self._selectedColor = selectedColor
        self._colorOutput = colorOutput
    }
    
    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .cyan, .blue, .indigo, .purple, .pink,
        .brown, .gray
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preset colors grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedColor == color {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 3)
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: color.opacity(0.3), radius: 3)
                        .onTapGesture {
                            selectedColor = color
                            colorOutput = ColorOutput(color: color)
                        }
                }
            }
            
            Divider()
            
            // Custom color picker
            HStack {
                Text("Custom:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .onChange(of: selectedColor) { _, newColor in
                        colorOutput = ColorOutput(color: newColor)
                    }
                
                Spacer()
                
                // Show selected color info
                if let output = colorOutput {
                    Text(output.hex)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var color: Color = .blue
        @State var output: ColorOutput? = nil
        
        var body: some View {
            ColorInputView(selectedColor: $color, colorOutput: $output)
                .padding()
        }
    }
    return PreviewWrapper()
}
